import Foundation
import MultipeerConnectivity

class Room: NSObject, NSCoding {
    static var instance = Room()
    static let cpuUUID = "CPU"
    static let accessCodeAllowedCharacters: NSString = "abcdefghijklmnopqrstuvwxyz"

    var name: String
    var players = [Player]()
    var connectedPeers = [MCPeerID: String]()

    private var uuid: String
    private var accessCode: String

    // MARK: Constructor/Destructor
    override init() {
        self.uuid = NSUUID().UUIDString
        self.accessCode = Room.generateAccessCode()
        self.name = self.accessCode     // Backwards compatibility with v1.0
    }

    // Backwards compatibility with v1.0
    convenience init(name: String,
                     uuid: String,
                     players: [Player],
                     connectedPeers: [MCPeerID: String]) {
        self.init()
        self.name = name
        self.uuid = uuid
        self.players = players
        self.connectedPeers = connectedPeers
    }

    convenience init(name: String,
                     uuid: String,
                     accessCode: String,
                     players: [Player],
                     connectedPeers: [MCPeerID: String]) {
        self.init()
        self.name = name
        self.uuid = uuid
        self.accessCode = accessCode
        self.players = players
        self.connectedPeers = connectedPeers
    }

    deinit {
        self.players.removeAll()
        self.connectedPeers.removeAll()
    }

    // MARK: Coder
    func encodeWithCoder(aCoder: NSCoder) {
        aCoder.encodeObject(self.name, forKey: SCCodingConstants.name)
        aCoder.encodeObject(self.uuid, forKey: SCCodingConstants.uuid)
        aCoder.encodeObject(self.players, forKey: SCCodingConstants.players)
        aCoder.encodeObject(self.connectedPeers, forKey: SCCodingConstants.connectedPeers)
        aCoder.encodeObject(self.accessCode, forKey: SCCodingConstants.accessCode)
    }

    required convenience init?(coder aDecoder: NSCoder) {
        if let name = aDecoder.decodeObjectForKey(SCCodingConstants.name) as? String,
               uuid = aDecoder.decodeObjectForKey(SCCodingConstants.uuid) as? String,
               players = aDecoder.decodeObjectForKey(SCCodingConstants.players) as? [Player],
               connectedPeers = aDecoder.decodeObjectForKey(SCCodingConstants.connectedPeers) as? [MCPeerID: String] {
            if let accessCode = aDecoder.decodeObjectForKey(SCCodingConstants.accessCode) as? String {
                self.init(
                    name: name,
                    uuid: uuid,
                    accessCode: accessCode,
                    players: players,
                    connectedPeers: connectedPeers
                )
            } else {
                // Backwards compatibility with v1.0
                self.init(
                    name: name,
                    uuid: uuid,
                    players: players,
                    connectedPeers: connectedPeers
                )
            }
        } else {
            self.init()
        }
    }

    // MARK: Public
    func refresh() {
        self.players.sortInPlace({ player1, player2 in
            if player1.team.rawValue < player2.team.rawValue {
                return true
            } else if player1.team.rawValue == player2.team.rawValue {
                return player1.isClueGiver()
            } else {
                return false
            }
        })

        if self.getClueGiverUUIDForTeam(Team.Red) == nil {
            self.autoAssignCluegiverForTeam(Team.Red)
        }

        if self.getClueGiverUUIDForTeam(Team.Blue) == nil {
            self.autoAssignCluegiverForTeam(Team.Blue)
        }
    }

    func generateNewAccessCode() {
        self.accessCode = Room.generateAccessCode()
        self.name = self.accessCode
    }

    func getUUID() -> String {
        return self.uuid
    }

    func setUUID(uuid: String) {
        self.uuid = uuid
    }

    func getAccessCode() -> String {
        return self.accessCode
    }

    func addPlayer(player: Player) {
        self.players.append(player)
    }

    func addCPUPlayer() {
        let cpu = Player(
            name: "CPU",
            uuid: Room.cpuUUID,
            team: Team.Blue,
            clueGiver: true,
            host: false
        )
        self.players.append(cpu)
    }

    func removeCPUPlayer() {
        self.removePlayerWithUUID(Room.cpuUUID)
    }

    func autoAssignCluegiverForTeam(team: Team) {
        for player in self.players {
            if player.team == team {
                player.setIsClueGiver(true)
                return
            }
        }
    }

    func getPlayerWithUUID(uuid: String) -> Player? {
        let filtered = self.players.filter({
            ($0 as Player).getUUID() == uuid
        })
        if filtered.count == 1 {
            return filtered[0]
        } else {
            return nil
        }
    }

    func setNameOfPlayerAtIndex(index: Int, name: String) {
        if index < self.players.count {
            self.players[index].name = name
        }
    }

    func removePlayerAtIndex(index: Int) {
        if index < self.players.count {
            self.players.removeAtIndex(index)
        }
    }

    func removePlayerWithUUID(uuid: String) {
        self.players = self.players.filter({
            ($0 as Player).getUUID() != uuid
        })
    }

    func playerWithUUIDInRoom(uuid: String) -> Bool {
        return self.getPlayerWithUUID(uuid) != nil
    }

    func teamSizesValid() -> Bool {
        if GameMode.instance.mode == GameMode.Mode.RegularGame {
            let redValid = self.players.filter({
                ($0 as Player).team == Team.Red
            }).count >= 2
            let blueValid = self.players.filter({
                ($0 as Player).team == Team.Blue
            }).count >= 2

            if redValid && blueValid {
                return true
            }

            return false
        } else {    // Minigame
            if self.players.count == 3 ||
               self.players.count == 4 {
                return true
            }

            return false
        }
    }

    func cluegiversSelected() -> Bool {
        if GameMode.instance.mode == GameMode.Mode.RegularGame {
            if self.getClueGiverUUIDForTeam(Team.Red) != nil &&
               self.getClueGiverUUIDForTeam(Team.Blue) != nil {
                return true
            }

            return false
        } else {    // Minigame
            if self.getClueGiverUUIDForTeam(Team.Red) != nil &&
               self.getClueGiverUUIDForTeam(Team.Blue) != nil {
                return true
            }

            return false
        }
    }

    func canStartGame() -> Bool {
        return teamSizesValid() && cluegiversSelected()
    }

    func getClueGiverUUIDForTeam(team: Team) -> String? {
        let filtered = self.players.filter({
            ($0 as Player).isClueGiver() && ($0 as Player).team == team
        })
        if filtered.count == 1 {
            return filtered[0].getUUID()
        } else {
            return nil
        }
    }

    func resetPlayers() {
        for player in players {
            player.clueGiver = false
            player.team = Team.Red
        }
    }

    func reset() {
        self.players.removeAll()
        self.connectedPeers.removeAll()
    }

    // MARK: Private
    private static func generateAccessCode() -> String {
        var result = ""

        for _ in 0 ..< SCConstants.accessCodeLength {
            let rand = arc4random_uniform(UInt32(Room.accessCodeAllowedCharacters.length))
            var nextChar = Room.accessCodeAllowedCharacters.characterAtIndex(Int(rand))
            result += NSString(characters: &nextChar, length: 1) as String
        }

        return result
    }
}
