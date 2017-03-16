import Foundation
import MultipeerConnectivity

class Room: NSObject, NSCoding {
    static var instance = Room()
    static let CPU_UUID = "CPU"
    static let accessCodeAllowedCharacters: NSString = "abcdefghijklmnopqrstuvwxyz"
    
    var name: String
    var players = [Player]()
    var connectedPeers = [MCPeerID: String]()
    
    fileprivate var uuid: String
    fileprivate var accessCode: String
    
    override init() {
        self.uuid = UUID().uuidString
        self.accessCode = Room.generateAccessCode()
        self.name = self.accessCode     // Backwards compatibility with v1.0
    }
    
    // Backwards compatibility with v1.0
    convenience init(name: String, uuid: String, players: [Player], connectedPeers: [MCPeerID: String]) {
        self.init()
        self.name = name
        self.uuid = uuid
        self.players = players
        self.connectedPeers = connectedPeers
    }
    
    convenience init(name: String, uuid: String, accessCode: String, players: [Player], connectedPeers: [MCPeerID: String]) {
        self.init()
        self.name = name
        self.uuid = uuid
        self.accessCode = accessCode
        self.players = players
        self.connectedPeers = connectedPeers
    }
    
    required convenience init?(coder aDecoder: NSCoder) {
        if let name = aDecoder.decodeObject(forKey: "name") as? String,
               let uuid = aDecoder.decodeObject(forKey: "uuid") as? String,
               let players = aDecoder.decodeObject(forKey: "players") as? [Player],
               let connectedPeers = aDecoder.decodeObject(forKey: "connectedPeers") as? [MCPeerID: String] {
            if let accessCode = aDecoder.decodeObject(forKey: "accessCode") as? String {
                self.init(name: name, uuid: uuid, accessCode: accessCode, players: players, connectedPeers: connectedPeers)
            } else {
                // Backwards compatibility with v1.0
                self.init(name: name, uuid: uuid, players: players, connectedPeers: connectedPeers)
            }
        } else {
            self.init()
        }
    }
    
    deinit {
        self.players.removeAll()
        self.connectedPeers.removeAll()
    }
    
    fileprivate static func generateAccessCode() -> String {
        var result = ""
        
        for _ in 0 ..< SCConstants.accessCodeLength {
            let rand = arc4random_uniform(UInt32(Room.accessCodeAllowedCharacters.length))
            var nextChar = Room.accessCodeAllowedCharacters.character(at: Int(rand))
            result += NSString(characters: &nextChar, length: 1) as String
        }
        
        return result
    }
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(self.name, forKey: "name")
        aCoder.encode(self.uuid, forKey: "uuid")
        aCoder.encode(self.accessCode, forKey: "accessCode")
        aCoder.encode(self.players, forKey: "players")
        aCoder.encode(self.connectedPeers, forKey: "connectedPeers")
    }
    
    func refresh() {
        self.players.sort(by: { player1, player2 in
            if player1.team.rawValue < player2.team.rawValue {
                return true
            } else if player1.team.rawValue == player2.team.rawValue {
                return player1.isClueGiver()
            } else {
                return false
            }
        })
        
        if self.getClueGiverUUIDForTeam(Team.red) == nil {
            self.autoAssignCluegiverForTeam(Team.red)
        }
        
        if self.getClueGiverUUIDForTeam(Team.blue) == nil {
            self.autoAssignCluegiverForTeam(Team.blue)
        }
    }
    
    func generateNewAccessCode() {
        self.accessCode = Room.generateAccessCode()
        self.name = self.accessCode
    }
    
    func getUUID() -> String {
        return self.uuid
    }
    
    func setUUID(_ uuid: String) {
        self.uuid = uuid
    }
    
    func getAccessCode() -> String {
        return self.accessCode
    }
    
    func addPlayer(_ player: Player) {
        self.players.append(player)
    }
    
    func addCPUPlayer() {
        let cpu = Player(name: "CPU", uuid: Room.CPU_UUID, team: Team.blue, clueGiver: true, host: false)
        self.players.append(cpu)
    }
    
    func removeCPUPlayer() {
        self.removePlayerWithUUID(Room.CPU_UUID)
    }
    
    func autoAssignCluegiverForTeam(_ team: Team) {
        for player in self.players {
            if player.team == team {
                player.setIsClueGiver(true)
                return
            }
        }
    }
    
    func getPlayerWithUUID(_ uuid: String) -> Player? {
        let filtered = self.players.filter({($0 as Player).getUUID() == uuid})
        if filtered.count == 1 {
            return filtered[0]
        }
        else {
            return nil
        }
    }
    
    func setNameOfPlayerAtIndex(_ index: Int, name: String) {
        if index < self.players.count {
            self.players[index].name = name
        }
    }
    
    func removePlayerAtIndex(_ index: Int) {
        if index < self.players.count {
            self.players.remove(at: index)
        }
    }
    
    func removePlayerWithUUID(_ uuid: String) {
        self.players = self.players.filter({($0 as Player).getUUID() != uuid})
    }
    
    func playerWithUUIDInRoom(_ uuid: String) -> Bool {
        return self.getPlayerWithUUID(uuid) != nil
    }
    
    func teamSizesValid() -> Bool {
        if GameMode.instance.mode == GameMode.Mode.regularGame {
            let redValid = self.players.filter({($0 as Player).team == Team.red}).count >= 2
            let blueValid = self.players.filter({($0 as Player).team == Team.blue}).count >= 2
            
            if redValid && blueValid {
                return true
            }
            
            return false
        } else {    // Minigame
            if self.players.count == 3 || self.players.count == 4 {
                return true
            }
            
            return false
        }
    }
    
    func cluegiversSelected() -> Bool {
        if GameMode.instance.mode == GameMode.Mode.regularGame {
            if self.getClueGiverUUIDForTeam(Team.red) != nil && self.getClueGiverUUIDForTeam(Team.blue) != nil {
                return true
            }
            
            return false
        } else {    // Minigame
            if self.getClueGiverUUIDForTeam(Team.red) != nil && self.getClueGiverUUIDForTeam(Team.blue) != nil {
                return true
            }

            return false
        }
    }
    
    func canStartGame() -> Bool {
        return teamSizesValid() && cluegiversSelected()
    }
    
    func getClueGiverUUIDForTeam(_ team: Team) -> String? {
        let filtered = self.players.filter({($0 as Player).isClueGiver() && ($0 as Player).team == team})
        if filtered.count == 1 {
            return filtered[0].getUUID()
        }
        else {
            return nil
        }
    }
    
    func resetPlayers() {
        for player in players {
            player.clueGiver = false
            player.team = Team.red
        }
    }
    
    func reset() {
        self.players.removeAll()
        self.connectedPeers.removeAll()
    }
}
