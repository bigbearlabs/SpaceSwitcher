import AppKit
import BBLSpaces



class SpacesSwitcherStatusItemController: StatusItemController {
  
  override init(image: NSImage, onClick: @escaping (StatusItemController) -> () = {_ in }) {
    super.init(image: image, onClick: onClick)
    
    self.menu = NSMenu(title: "statusItemMenu")
    
    _ = spacesObservation
  }
  
  var spacesInfo: SpacesInfo! {
    didSet {
      self.previousSpacesInfo = oldValue
      
      self.refreshMenu()
    }
  }
  
  var previousSpacesInfo: SpacesInfo?
  
  lazy var spacesObservation = {
    SpacesChangeObserver { [unowned self] spacesInfo in
      self.spacesInfo = spacesInfo
    }
  }()
  
  
  func refreshMenu() {
    self.menu!.items = self.spacesMenuItems
  }
  
  
  @IBAction
  func action_selected(menuItem: NSMenuItem) {
    
    let spaceToken = menuItem.representedObject as! Int
    
    spaceSwitcher.switchToSpace(token: spaceToken)
  }
  
  
  var spacesMenuItems: [NSMenuItem] {
    let state = stateTuple(self.spacesInfo, self.previousSpacesInfo?.currentSpaceIds.map { $0.intValue } ?? [])
    let labelTuples = spaceSwitchLabelTuples(from: state)
    
    let menuItems: [NSMenuItem] = labelTuples.map {
      let (label, token) = $0
      let o = NSMenuItem(title: label, action: #selector(action_selected(menuItem:)), keyEquivalent: "")
      o.target = self
      o.representedObject = token
      return o
    }
    return menuItems
  }
  
}



// MARK: - cribbed from bigbearlabs/BBLBasics


open class StatusItemController {
  
  let image: NSImage
  
  let onClick: (StatusItemController) -> ()
  
  
  private lazy var statusItem: NSStatusItem = {
    let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    
    item.button?.image = self.image
    
    item.button?.target = self
    item.button?.action = #selector(action_buttonClicked(_:))
    
    item.highlightMode = true
    
    return item
  }()
  
  
  public init(image: NSImage, onClick: @escaping (StatusItemController) -> () = {_ in }) {
    
    self.image = image
    self.onClick = onClick
    
    _ = self.statusItem
  }
  
  public var menu: NSMenu? {
    get {
      return self.statusItem.menu
    }
    set {
      self.statusItem.menu = newValue
    }
  }
  
  @IBAction
  func action_buttonClicked(_ sender: NSButton) {
    onClick(self)
  }
  
  
  
  public var view: NSView? {
    return self.statusItem.button
  }
  
}
