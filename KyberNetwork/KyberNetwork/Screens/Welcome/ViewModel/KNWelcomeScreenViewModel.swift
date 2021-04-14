// Copyright SIX DAY LLC. All rights reserved.

import UIKit

struct KNWelcomeScreenViewModel {

  public struct KNWelcomeData {
    let icon: String
    let title: String
    let subtitle: String
    let position: Int

    
  }

  let dataList: [KNWelcomeData]

  init() {
    let page1 = KNWelcomeData(icon: "intro_page_1", title: "Swap", subtitle: "Swap any token to any token at the best rates", position: 1)
    let page2 = KNWelcomeData(icon: "intro_page_2", title: "Earn", subtitle: "Earn interest from idle assets in real time", position: 2)
    let page3 = KNWelcomeData(icon: "intro_page_3", title: "Manage Your Portfolio", subtitle: "Track and manage your digital assets ", position: 3)
    let page4 = KNWelcomeData(icon: "intro_page_4", title: "Get Rewards", subtitle: "Enjoy bonus rewards by participating in Krystal activities", position: 4)
    self.dataList = [page1, page2, page3, page4]
  }

  var numberRows: Int { return self.dataList.count }

  func welcomeData(at row: Int) -> KNWelcomeData {
    return self.dataList[row]
  }
}
