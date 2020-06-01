//Created  on 2019/3/12 by  LCD:https://github.com/liucaide .

/***** 模块文档 *****
 *
 */



import Foundation
import UIKit
import CaamDauExtension
import CaamDauNet
import SwiftyJSON
import Cache
class ViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        var page = 1
        CD_Net()
            .baseURL("https://httpbin.org/")
            .path("get")
            .method(.get)
            .parameters(["foo": "bar"])
            .onCache(completion: { (data) in
                debugPrint("Cache JSON:", JSON(data))
            })
            .toCache(when: {_ in page == 1})
            .success({ (res) in
                print(res)
            })
            /*.mapModel(withCodable: M_Codable<M_CodableData>.self, succeed: { (m) in
                debugPrint(m.code)
                debugPrint(m.data.host)
            })
            
            .mapModel(withSwiftyJSON: M_Test<M_T>.self, tag: 1)
            { (m) in
                debugPrint(m.code)
                debugPrint(m.data.host)
            }*/
            .failure({ (error) in
                debugPrint(error.code)
                debugPrint(error.massage)
            })
            //.responseStyle(.data)
            .responseStyle(.json)
            .request()
            //.request(isSubjoin: false, handler:nil)
            // isSubjoin: 默认增补token等通用参数, handler: 增补操作 如参数签名
            // 不需要增补的接口设为 false 即可
        
        
        
        
        
    }
}



