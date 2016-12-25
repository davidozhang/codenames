import Foundation
import MultipeerConnectivity

class Room: NSObject, NSCoding {
    static var instance = Room()
    static let accessCodeLength = 4
    
    var name: String
    var players = [Player]()
    var connectedPeers = [MCPeerID: String]()
    
    private var uuid: String
    private var accessCode: String
    
    override init() {
        self.uuid = NSUUID().UUIDString
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
        if let name = aDecoder.decodeObjectForKey("name") as? String, uuid = aDecoder.decodeObjectForKey("uuid") as? String, accessCode = aDecoder.decodeObjectForKey("accessCode") as? String, players = aDecoder.decodeObjectForKey("players") as? [Player], connectedPeers = aDecoder.decodeObjectForKey("connectedPeers") as? [MCPeerID: String] {
            self.init(name: name, uuid: uuid, accessCode: accessCode, players: players, connectedPeers: connectedPeers)
        } else if let name = aDecoder.decodeObjectForKey("name") as? String, uuid = aDecoder.decodeObjectForKey("uuid") as? String, players = aDecoder.decodeObjectForKey("players") as? [Player], connectedPeers = aDecoder.decodeObjectForKey("connectedPeers") as? [MCPeerID: String] {
            // Backwards compatibility with v1.0
            self.init(name: name, uuid: uuid, players: players, connectedPeers: connectedPeers)
        } else {
            self.init()
        }
    }
    
    deinit {
        self.players.removeAll()
        self.connectedPeers.removeAll()
    }
    
    private static func generateAccessCode() -> String {
        let letters : NSString = "abcdefghijklmnopqrstuvwxyz0123456789"
        var result = ""
        
        for _ in 0 ..< accessCodeLength {
            let rand = arc4random_uniform(UInt32(letters.length))
            var nextChar = letters.characterAtIndex(Int(rand))
            result += NSString(characters: &nextChar, length: 1) as String
        }
        
        return result
    }
    
    func encodeWithCoder(aCoder: NSCoder) {
        aCoder.encodeObject(self.name, forKey: "name")
        aCoder.encodeObject(self.uuid, forKey: "uuid")
        aCoder.encodeObject(self.accessCode, forKey: "accessCode")
        aCoder.encodeObject(self.players, forKey: "players")
        aCoder.encodeObject(self.connectedPeers, forKey: "connectedPeers")
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
    
    func getPlayerWithUUID(uuid: String) -> Player? {
        let filtered = self.players.filter({($0 as Player).getUUID() == uuid})
        if filtered.count == 1 {
            return filtered[0]
        }
        else {
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
        self.players = self.players.filter({($0 as Player).getUUID() != uuid})
    }
    
    func playerWithUUIDInRoom(uuid: String) -> Bool {
        return self.getPlayerWithUUID(uuid) != nil
    }
    
    func canStartGame() -> Bool {
        if GameMode.instance.mode == GameMode.Mode.RegularGame && self.players.count >= 4 {
            let redValid = self.players.filter({($0 as Player).team == Team.Red}).count >= 2
            let blueValid = self.players.filter({($0 as Player).team == Team.Blue}).count >= 2
            
            if redValid && blueValid && self.getClueGiverUUIDForTeam(Team.Red) != nil && self.getClueGiverUUIDForTeam(Team.Blue) != nil {
                return true
            }
            else {
                return false
            }
        }
        else if GameMode.instance.mode == GameMode.Mode.MiniGame && (self.players.count == 2 || self.players.count == 3) {
            if self.getClueGiverUUIDForTeam(Team.Red) != nil || self.getClueGiverUUIDForTeam(Team.Blue) != nil {
                return true
            }
            else {
                return false
            }
        }
        else {
            return false
        }
    }
    
    func getClueGiverUUIDForTeam(team: Team) -> String? {
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
            player.team = Team.Red
        }
    }
    
    func reset() {
        self.players.removeAll()
        self.connectedPeers.removeAll()
    }
}
