//
//  CarInfo+CAN.swift
//  CarDash
//
//  Created by Alexandre Blin on 12/06/2016.
//  Copyright © 2016 Alexandre Blin. All rights reserved.
//

import Foundation

extension UInt16 {
    init(highByte: UInt8, lowByte: UInt8) {
        self = UInt16(highByte) << 8 | UInt16(lowByte)
    }
}

func isInfoMessage(_ data: [UInt8], b1: UInt8, b2: UInt8, b3: UInt8) -> Bool {
    return ((data[0] & 0x0F) == b1 && (data[1] & 0xFF) == b2 && (data[2] & 0xF0) == (b3 & 0xF0))
}

extension CarInfo: SerialParserDelegate {
    func serialParser(_ serialParser: SerialParser, didReceiveFrame frameID: UInt8, data: [UInt8]) {
        switch frameID {
        case 0x01: // Volume
            volume = Int(data[0])
        case 0x02: // Temperature
            let signedTemperature = Int16(data[0])
            temperature = Int(signedTemperature < 128 ? signedTemperature : signedTemperature - 256)
        case 0x03: // Radio source
            switch data[0] {
            case 1:
                radioSource = .fmTuner
            case 4:
                radioSource = .phone
            case 5:
                radioSource = .aux
            default:
                print("Unknown radio source \(data[0])")
            }
        case 0x04: // Radio station name
            var actualLength = data.count
            if let nullIndex = data.index(of: 0x00) {
                actualLength = nullIndex
            }

            radioName = String(data: Data(bytes: UnsafePointer<UInt8>(data), count: actualLength),
                               encoding: String.Encoding.ascii)
        case 0x05: // Radio station frequency
            radioFrequency = String(format: "%.2f", Double(UInt16(highByte: data[0], lowByte: data[1])) / 10.0)
        case 0x06: // Radio FM type
            switch data[0] {
            case 1:
                radioBandName = "1"
            case 2:
                radioBandName = "2"
            case 4:
                radioBandName = "AST"
            default:
                print("Unknown radio band \(data[0])")
            }
        case 0x07: // Radio station description
            var actualLength = data.count
            if let nullIndex = data.index(of: 0x00) {
                actualLength = nullIndex
            }

            radioDescription = String(data: Data(bytes: UnsafePointer<UInt8>(data), count: actualLength),
                                      encoding: String.Encoding.ascii)
        case 0x08: // Car information message
            parseInfoMessage(data)
        case 0x0C, 0x0D: // Trip info
            let tripInfo = TripInfo(distance: Int(UInt16(highByte: data[1], lowByte: data[2])),
                                    averageFuelUsage: data[3] == 0xFF ?
                                        -1 :
                                        Double(UInt16(highByte: data[3], lowByte: data[4])) / 10.0,
                                    averageSpeed: data[0] == 0xFF ? -1 : Int(data[0]))

            if frameID == 0x0C {
                tripInfo1 = tripInfo
            } else {
                tripInfo2 = tripInfo
            }
        case 0x0E: // Instant info
            instantInfo = InstantInfo(autonomy: data[3] == 0xFF ? -1 : Int(UInt16(highByte: data[3], lowByte: data[4])),
                                      fuelUsage: data[1] == 0xFF ?
                                        0 :
                                        Double(UInt16(highByte: data[1], lowByte: data[2])) / 10.0)
        case 0x0F: // Trip mode
            switch data[0] {
            case 0:
                tripInfoMode = .instant
            case 1:
                tripInfoMode = .trip1
            case 2:
                tripInfoMode = .trip2
            default:
                print("Unknown trip mode \(data[0])")
            }
        case 0x10: // Audio settings
            var activeMode = AudioSettings.Mode.none
            if (data[0] & 0x80) == 0x80 {
                activeMode = .leftRightBalance
            } else if (data[1] & 0x80) == 0x80 {
                activeMode = .frontRearBalance
            } else if (data[2] & 0x80) == 0x80 {
                activeMode = .bass
            } else if (data[4] & 0x80) == 0x80 {
                activeMode = .treble
            } else if (data[5] & 0x80) == 0x80 {
                activeMode = .loudness
            } else if (data[5] & 0x10) == 0x10 {
                activeMode = .automaticVolume
            } else if (data[6] & 0x40) == 0x40 {
                activeMode = .equalizer
            }

            var equalizerSetting = AudioSettings.EqualizerSetting.none
            switch data[6] & 0xBF { // exclude the "active mode" bit
            case 0x07:
                equalizerSetting = .classical
            case 0x0B:
                equalizerSetting = .jazzBlues
            case 0x0F:
                equalizerSetting = .popRock
            case 0x13:
                equalizerSetting = .vocals
            case 0x17:
                equalizerSetting = .techno
            default:
                equalizerSetting = .none
            }

            audioSettings = AudioSettings(activeMode: activeMode,
                                          frontRearBalance: Int(data[1] & 0x7F) - 63,
                                          leftRightBalance: Int(data[0] & 0x7F) - 63,
                                          automaticVolume: (data[5] & 0x07) == 0x07,
                                          equalizer: equalizerSetting,
                                          bass: Int(data[2] & 0x7F) - 63,
                                          treble: Int(data[4] & 0x7F) - 63,
                                          loudness: (data[5] & 0x40) == 0x40)
        case 0x42:
            secretButton = data[0] != 0
        default:
            print("Unknown frame ID \(frameID)")
        }
    }

    /// Parses raw info message from the CAN bus and sets the corresponding message
    /// to the `infoMessage` property
    ///
    /// - Parameter data: The raw data to parse
    func parseInfoMessage(_ data: [UInt8]) {
        if isInfoMessage(data, b1: 0x01, b2: 0x2F, b3: 0xC4) {
            infoMessage = "Essuie-vitre automatique activé"
        } else if isInfoMessage(data, b1: 0x01, b2: 0x30, b3: 0xC4) {
            infoMessage = "Essuie-vitre automatique désactivé"
        } else if isInfoMessage(data, b1: 0x01, b2: 0x31, b3: 0xC4) {
            infoMessage = "Allumage automatique des projecteurs activé"
        } else if isInfoMessage(data, b1: 0x01, b2: 0x32, b3: 0xC4) {
            infoMessage = "Allumage automatique des projecteurs désactivé"
        } else if isInfoMessage(data, b1: 0x01, b2: 0x33, b3: 0xC4) {
            infoMessage = "Auto-verrouillage des portes activé"
        } else if isInfoMessage(data, b1: 0x01, b2: 0x34, b3: 0xC4) {
            infoMessage = "Auto-verrouillage des portes déactivé"
        } else if isInfoMessage(data, b1: 0x01, b2: 0x37, b3: 0xC4) {
            infoMessage = "Sécurité enfant activée"
        } else if isInfoMessage(data, b1: 0x01, b2: 0x38, b3: 0xC4) {
            infoMessage = "Sécurité enfant désactivée"
        } else if isInfoMessage(data, b1: 0x01, b2: 0x3D, b3: 0xC4) {
            infoMessage = "Stationnement NON (cf photo)"
        } else if isInfoMessage(data, b1: 0x01, b2: 0x98, b3: 0xC4) {
            infoMessage = "Système STOP START défaillant"
        } else if isInfoMessage(data, b1: 0x01, b2: 0xF6, b3: 0xC4) {
            infoMessage = "Manoeuvre toit impossible: tº ext. trop faible"
        } else if isInfoMessage(data, b1: 0x01, b2: 0xF7, b3: 0xC4) {
            infoMessage = "Manoeuvre toit impossible: vitesse trop élevée"
        } else if isInfoMessage(data, b1: 0x01, b2: 0xF8, b3: 0xC4) {
            infoMessage = "Manoeuvre toit impossible: coffre ouvert"
        } else if isInfoMessage(data, b1: 0x01, b2: 0xFA, b3: 0xC4) {
            infoMessage = "Manoeuvre toit impossible: rideau coffre non déployé"
        } else if isInfoMessage(data, b1: 0x01, b2: 0xFB, b3: 0xC4) {
            infoMessage = "Manoeuvre toit terminée"
        } else if isInfoMessage(data, b1: 0x01, b2: 0xFC, b3: 0xC4) {
            infoMessage = "Terminer immédiatement la manoeuvre de toit"
        } else if isInfoMessage(data, b1: 0x01, b2: 0xFD, b3: 0xC4) {
            infoMessage = "Manoeuvre impossible: toit verrouillé"
        } else if isInfoMessage(data, b1: 0x01, b2: 0xFE, b3: 0xC4) {
            infoMessage = "Mécanisme toit escamotable défaillant"
        } else if isInfoMessage(data, b1: 0x01, b2: 0xFF, b3: 0xC4) {
            infoMessage = "Manoeuvre impossible: lunette ouverte"
        } else if isInfoMessage(data, b1: 0x00, b2: 0x00, b3: 0xC8) {
            infoMessage = "Diagnostic OK"
        } else if isInfoMessage(data, b1: 0x00, b2: 0x01, b3: 0xC8) {
            infoMessage = "STOP: défaut température moteur, arrêtez le véhicule"
        } else if isInfoMessage(data, b1: 0x00, b2: 0x03, b3: 0xC8) {
            infoMessage = "Ajustez niveau liquide de refroidissement"
        } else if isInfoMessage(data, b1: 0x00, b2: 0x04, b3: 0xC8) {
            infoMessage = "Ajustez le niveau d'huile moteur"
        } else if isInfoMessage(data, b1: 0x00, b2: 0x05, b3: 0xC8) {
            infoMessage = "STOP: défaut pression huile moteur, arrêtez le véhicule"
        } else if isInfoMessage(data, b1: 0x00, b2: 0x08, b3: 0xC8) {
            infoMessage = "STOP: système de freinage défaillant"
        } else if isInfoMessage(data, b1: 0x00, b2: 0x0A, b3: 0xC8) {
            infoMessage = "Demande non permise (cf photo)"
        } else if isInfoMessage(data, b1: 0x00, b2: 0x0D, b3: 0xC8) {
            infoMessage = "Plusieurs roues crevées"
        } else if isInfoMessage(data, b1: 0x00, b2: 0x0F, b3: 0xC8) {
            infoMessage = "Risque de colmatage filtre à particules: consultez la notice"
        } else if isInfoMessage(data, b1: 0x00, b2: 0x11, b3: 0xC8) {
            infoMessage = "Suspension défaillante, vitesse max 90km/h"
        } else if isInfoMessage(data, b1: 0x00, b2: 0x12, b3: 0xC8) {
            infoMessage = "Suspension défaillante"
        } else if isInfoMessage(data, b1: 0x00, b2: 0x13, b3: 0xC8) {
            infoMessage = "Direction assistée défaillante"
        } else if isInfoMessage(data, b1: 0x00, b2: 0x14, b3: 0xC8) {
            infoMessage = "WTF?"
        } else if isInfoMessage(data, b1: 0x00, b2: 0x61, b3: 0xC8) {
            infoMessage = "Frein de parking serré"
        } else if isInfoMessage(data, b1: 0x00, b2: 0x62, b3: 0xC8) {
            infoMessage = "Frein de parking desserré"
        } else if isInfoMessage(data, b1: 0x00, b2: 0x64, b3: 0xC8) {
            infoMessage = "Commande frein de parking défaillante, frein de parking auto activé"
        } else if isInfoMessage(data, b1: 0x00, b2: 0x67, b3: 0xC8) {
            infoMessage = "Plaquettes de frein usées"
        } else if isInfoMessage(data, b1: 0x00, b2: 0x68, b3: 0xC8) {
            infoMessage = "Frein de parking défaillant"
        } else if isInfoMessage(data, b1: 0x00, b2: 0x69, b3: 0xC8) {
            infoMessage = "Aileron mobile défaillant, vitesse limitée, consultez la notice"
        } else if isInfoMessage(data, b1: 0x00, b2: 0x6A, b3: 0xC8) {
            infoMessage = "Système de freinage ABS défaillant"
        } else if isInfoMessage(data, b1: 0x00, b2: 0x6B, b3: 0xC8) {
            infoMessage = "Système ESP/ASR défaillant"
        } else if isInfoMessage(data, b1: 0x00, b2: 0x6C, b3: 0xC8) {
            infoMessage = "Suspension défaillante"
        } else if isInfoMessage(data, b1: 0x00, b2: 0x6D, b3: 0xC8) {
            infoMessage = "STOP: direction assistée défaillante"
        } else if isInfoMessage(data, b1: 0x00, b2: 0x6E, b3: 0xC8) {
            infoMessage = "Défaut boite de vitesse, faites réparer le véhicule"
        } else if isInfoMessage(data, b1: 0x00, b2: 0x6F, b3: 0xC8) {
            infoMessage = "Système de controle de vitesse défaillant"
        } else if isInfoMessage(data, b1: 0x00, b2: 0x73, b3: 0xC8) {
            infoMessage = "Capteur de luminosité ambiante défaillant"
        } else if isInfoMessage(data, b1: 0x00, b2: 0x74, b3: 0xC8) {
            infoMessage = "Ampoule feu de position défaillante"
        } else if isInfoMessage(data, b1: 0x00, b2: 0x75, b3: 0xC8) {
            infoMessage = "Réglage automatique des projecteurs défaillant"
        } else if isInfoMessage(data, b1: 0x00, b2: 0x76, b3: 0xC8) {
            infoMessage = "Projecteurs directionnels défaillants"
        } else if isInfoMessage(data, b1: 0x00, b2: 0x78, b3: 0xC8) {
            infoMessage = "Airbag(s) ou ceinture(s) à prétensionneur(s) défaillant(s)"
        } else if isInfoMessage(data, b1: 0x00, b2: 0x7A, b3: 0xC8) {
            infoMessage = "Défaut boite de vitesse, faites réparer le véhicule"
        } else if isInfoMessage(data, b1: 0x00, b2: 0x7B, b3: 0xC8) {
            infoMessage = "Pied sur frein et levier en position \"N\" nécessaires"
        } else if isInfoMessage(data, b1: 0x00, b2: 0x7D, b3: 0xC8) {
            infoMessage = "Présence d'eau dans le filtre à gasoil, faites réparer le véhicule"
        } else if isInfoMessage(data, b1: 0x00, b2: 0x7E, b3: 0xC8) {
            infoMessage = "Défaut moteur, faites réparer le véhicule"
        } else if isInfoMessage(data, b1: 0x00, b2: 0x7F, b3: 0xC8) {
            infoMessage = "Défaut moteur, faites réparer le véhicule"
        } else if isInfoMessage(data, b1: 0x00, b2: 0x81, b3: 0xC8) {
            infoMessage = "Niveau additif FAP trop faible, faites réparer le véhicule"
        } else if isInfoMessage(data, b1: 0x00, b2: 0x83, b3: 0xC8) {
            infoMessage = "Antivol électronique défaillant"
        } else if isInfoMessage(data, b1: 0x00, b2: 0x88, b3: 0xC8) {
            infoMessage = "Système aide au stationnement défaillant"
        } else if isInfoMessage(data, b1: 0x00, b2: 0x89, b3: 0xC8) {
            infoMessage = "Système de mesure de place défaillant"
        } else if isInfoMessage(data, b1: 0x00, b2: 0x8A, b3: 0xC8) {
            infoMessage = "Charge batterie ou alimentation électrique défaillante"
        } else if isInfoMessage(data, b1: 0x00, b2: 0x8D, b3: 0xC8) {
            infoMessage = "Pression pneumatiques insuffisante"
        } else if isInfoMessage(data, b1: 0x00, b2: 0x97, b3: 0xC8) {
            infoMessage = "Système d'alerte de franchissement de ligne défaillant"
        } else if isInfoMessage(data, b1: 0x00, b2: 0x9A, b3: 0xC8) {
            infoMessage = "Ampoule feu de croisement défaillante"
        } else if isInfoMessage(data, b1: 0x00, b2: 0x9B, b3: 0xC8) {
            infoMessage = "Ampoule feu de route défaillante"
        } else if isInfoMessage(data, b1: 0x00, b2: 0x9C, b3: 0xC8) {
            infoMessage = "Ampoule feu stop défaillante"
        } else if isInfoMessage(data, b1: 0x00, b2: 0x9D, b3: 0xC8) {
            infoMessage = "Ampoule anti-brouillard défaillante"
        } else if isInfoMessage(data, b1: 0x00, b2: 0x9E, b3: 0xC8) {
            infoMessage = "Clignotant défaillant"
        } else if isInfoMessage(data, b1: 0x00, b2: 0x9F, b3: 0xC8) {
            infoMessage = "Ampoule feu de recul défaillante"
        } else if isInfoMessage(data, b1: 0x00, b2: 0xA0, b3: 0xC8) {
            infoMessage = "Ampoule feu de position défaillante"
        } else if isInfoMessage(data, b1: 0x00, b2: 0xCD, b3: 0xC8) {
            infoMessage = "Régulation de vitesse impossible: vitesse trop faible"
        } else if isInfoMessage(data, b1: 0x00, b2: 0xCE, b3: 0xC8) {
            infoMessage = "Activation du régulateur impossible: saisir la vitesse"
        } else if isInfoMessage(data, b1: 0x00, b2: 0xD2, b3: 0xC8) {
            infoMessage = "Ceintures AV non bouclées"
        } else if isInfoMessage(data, b1: 0x00, b2: 0xD3, b3: 0xC8) {
            infoMessage = "Ceintures passagers AR bouclées"
        } else if isInfoMessage(data, b1: 0x00, b2: 0xD7, b3: 0xC8) {
            infoMessage = "Placer boite automatique en position P"
        } else if isInfoMessage(data, b1: 0x00, b2: 0xD8, b3: 0xC8) {
            infoMessage = "Risque de verglas"
        } else if isInfoMessage(data, b1: 0x00, b2: 0xD9, b3: 0xC8) {
            infoMessage = "Oubli frein à main !"
        } else if isInfoMessage(data, b1: 0x00, b2: 0xDE, b3: 0xC8)
            || isInfoMessage(data, b1: 0x00, b2: 0x0B, b3: 0xC8) {
            // Car doors frame
            var decodedCarDoors = CarDoors.None

            let doorByte1 = data[3]
            let doorByte2 = data[4]

            if doorByte1 & 0x04 == 0x04 {
                decodedCarDoors.insert(.Hood)
            }

            if doorByte1 & 0x08 == 0x08 {
                decodedCarDoors.insert(.Trunk)
            }

            if doorByte1 & 0x10 == 0x10 {
                decodedCarDoors.insert(.RearLeft)
            }

            if doorByte1 & 0x20 == 0x20 {
                decodedCarDoors.insert(.RearRight)
            }

            if doorByte1 & 0x40 == 0x40 {
                decodedCarDoors.insert(.FrontLeft)
            }

            if doorByte1 & 0x80 == 0x80 {
                decodedCarDoors.insert(.FrontRight)
            }

            if doorByte2 & 0x40 == 0x40 {
                decodedCarDoors.insert(.FuelFlap)
            }

            carDoors = decodedCarDoors
        } else if isInfoMessage(data, b1: 0x00, b2: 0xDF, b3: 0xC8) {
            infoMessage = "Niveau liquide lave-glace insuffisant"
        } else if isInfoMessage(data, b1: 0x00, b2: 0xE0, b3: 0xC8) {
            infoMessage = "Niveau carburant faible"
        } else if isInfoMessage(data, b1: 0x00, b2: 0xE1, b3: 0xC8) {
            infoMessage = "Circuit de carburant neutralisé"
        } else if isInfoMessage(data, b1: 0x00, b2: 0xE3, b3: 0xC8) {
            infoMessage = "Pile télécommande plip usagée"
        } else if isInfoMessage(data, b1: 0x00, b2: 0xE5, b3: 0xC8) {
            infoMessage = "Pression pneumatique(s) non surveillée"
        } else if isInfoMessage(data, b1: 0x00, b2: 0xE7, b3: 0xC8) {
            infoMessage = "Vitesse élevée, vérifier si pression pneumatiques adaptée"
        } else if isInfoMessage(data, b1: 0x00, b2: 0xE8, b3: 0xC8) {
            infoMessage = "Pression pneumatique(s) insuffisante"
        } else if isInfoMessage(data, b1: 0x00, b2: 0xEB, b3: 0xC8) {
            infoMessage = "La phase de démarrage a échoué (consulter la notice)"
        } else if isInfoMessage(data, b1: 0x00, b2: 0xEC, b3: 0xC8) {
            infoMessage = "Démarrage prolongé en cours"
        } else if isInfoMessage(data, b1: 0x00, b2: 0xEF, b3: 0xC8) {
            infoMessage = "Télécommande non détectée"
        } else if isInfoMessage(data, b1: 0x00, b2: 0xF0, b3: 0xC8) {
            infoMessage = "Diagnostic en cours"
        } else if isInfoMessage(data, b1: 0x00, b2: 0xF1, b3: 0xC8) {
            infoMessage = "Diagnostic terminé"
        } else if isInfoMessage(data, b1: 0x00, b2: 0xF7, b3: 0xC8) {
            infoMessage = "Ceinture passager AR gauche débouclée"
        } else if isInfoMessage(data, b1: 0x00, b2: 0xF8, b3: 0xC8) {
            infoMessage = "Ceinture passager AR central débouclée"
        } else if isInfoMessage(data, b1: 0x00, b2: 0xF9, b3: 0xC8) {
            infoMessage = "Ceinture passager AR droit débouclée"
        } else {
            carDoors = .None
            infoMessage = nil
        }
    }

}
