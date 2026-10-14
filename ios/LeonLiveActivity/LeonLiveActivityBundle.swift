import WidgetKit
import SwiftUI

@main
struct LeonLiveActivityBundle: WidgetBundle {
    var body: some Widget {
        if #available(iOS 16.1, *) {
            LeonLiveActivityWidget()
        }
    }
}
