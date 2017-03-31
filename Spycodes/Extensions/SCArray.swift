import UIKit

extension Array {
    var shuffled: Array {
        var elements = self
        return elements.shuffle()
    }

    fileprivate mutating func shuffle() -> Array {
        indices.dropLast().forEach({
            guard case let index = Int(arc4random_uniform(UInt32(count - $0))) + $0, index != $0 else { return }

            swap(&self[$0], &self[index])
        })

        return self
    }

    func choose(_ n: Int) -> Array {
        return Array(shuffled.prefix(n))
    }
}
