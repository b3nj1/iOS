import Foundation
import RealmSwift
import ObjectMapper

public final class RLMScene: Object, UpdatableModel {
    @objc dynamic private var underlyingSceneData: Data = Data()

    @objc dynamic public var identifier: String = ""

    @objc dynamic private var backingPosition: Int = 0
    public static var positionKeyPath: String { #keyPath(RLMScene.backingPosition) }
    public var position: Int {
        set {
            backingPosition = newValue
            actions.forEach { $0.Position = newValue }
        }
        get {
            backingPosition
        }
    }

    @objc dynamic private var backingActionEnabled: Bool = true
    public var actionEnabled: Bool {
        set {
            backingActionEnabled = newValue
            updateAction()
        }
        get {
            backingActionEnabled
        }
    }
    public let actions = LinkingObjects<Action>(fromType: Action.self, property: #keyPath(Action.Scene))
    public var scene: Scene {
        set {
            do {
                underlyingSceneData = try JSONSerialization.data(withJSONObject: newValue.toJSON(), options: [])
            } catch {
                fatalError("couldn't serialize scene: \(scene)")
            }
        }
        get {
            do {
                let object = try JSONSerialization.jsonObject(with: underlyingSceneData, options: [])
                return Mapper<Scene>().map(JSONObject: object)!
            } catch {
                fatalError("couldn't deserialize scene: \(underlyingSceneData)")
            }
        }
    }

    init(scene: Scene) {
        super.init()
        self.scene = scene
    }

    required init() {

    }

    public override class func primaryKey() -> String? {
        #keyPath(identifier)
    }

    static func didUpdate(objects: [RLMScene]) {
        let sorted = objects.sorted { lhs, rhs in
            let lhsText = lhs.scene.FriendlyName ?? lhs.scene.ID
            let rhsText = rhs.scene.FriendlyName ?? rhs.scene.ID
            return lhsText < rhsText
        }

        for (idx, object) in sorted.enumerated() {
            object.position = 10_000 + idx
        }
    }

    func update(with object: Scene, using realm: Realm) {
        if self.realm == nil {
            self.identifier = object.ID
        } else {
            precondition(identifier == object.ID)
        }

        if object.Icon == nil {
            object.Icon = "mdi:palette"
        }

        self.scene = object
        updateAction()
    }

    private func updateAction() {
        guard actionEnabled else {
            for action in actions {
                self.realm?.delete(action)
            }
            return
        }

        let action = actions.first ?? Action()
        if action.realm == nil {
            action.ID = identifier
        } else {
            precondition(action.ID == identifier)
        }
        action.IconName = (scene.Icon ?? "mdi:alert").normalizingIconString
        action.Position = position
        action.Name = scene.FriendlyName ?? identifier
        action.Text = scene.FriendlyName ?? identifier
        action.BackgroundColor = "#FFFFFF"
        action.TextColor = "#000000"
        action.IconColor = "#000000"
        action.Scene = self
        realm?.add(action, update: .all)
    }
}
