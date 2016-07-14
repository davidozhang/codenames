import Foundation

class Lobby {
    static let instance = Lobby()
    var rooms = [Room]()
    
    func addRoomWithName(name: String) {
        let room = Room()
        room.setRoomName(name)
        self.rooms.append(room)
    }
    
    func getRooms() -> [Room] {
        return self.rooms
    }
    
    func getRoomWithName(name: String) -> Room? {
        for i in 0 ..< rooms.count {
            if rooms[i].getRoomName() == name {
                return rooms[i]
            }
        }
        
        return nil
    }
    
    func hasRoomWithName(name: String) -> Bool {
        for i in 0 ..< rooms.count {
            if rooms[i].getRoomName() == name {
                return true
            }
        }
        
        return false
    }
    
    func removeRoomWithName(name: String) {
        for i in 0 ..< rooms.count {
            if rooms[i].getRoomName() == name {
                rooms.removeAtIndex(i)
            }
        }
    }
    
    func getNumberOfRooms() -> Int {
        return self.rooms.count
    }
}