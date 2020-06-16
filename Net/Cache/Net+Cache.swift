//Created  on 2019/6/15 by  LCD:https://github.com/liucaide .

/***** 模块文档 *****
 *  扩展 Cache 功能 依赖 Cache 库: https://github.com/hyperoslo/Cache
 */




import Foundation
import Cache
import CaamDauExtension

public let storage:Storage<Data>? = {
    return try? Storage<Data>(diskConfig: DiskConfig(name: CD.appId), memoryConfig: MemoryConfig(expiry: .never, countLimit: 10, totalCostLimit: 10), transformer: TransformerFactory.forData())
}()

public extension Net {
    /// 默认使用 url ,相同url 增加 key 标识
    @discardableResult
    func onCache(withData key:String = "", completion:((Data) ->Void)?) -> Self {
        let urlPath = (self.baseURL + self.path) + (key.isEmpty ? "" : ("."+key))
        storage?.async.object(forKey: urlPath, completion: { [weak self](result) in
            switch result {
              case .value(let data):
                completion?(data)
              case .error(_):
                self?.failure?(Net.Error(code: -1100, massage: ""))
            }
        })
        return self
    }
    
    @discardableResult
    func toCache(withData key:String = "", when:@escaping (Data)->Bool = {_ in true}, customCache:((Data)->Data)? = nil) -> Self {
        self.cache = { res in
            guard when(res) else {return}
            let urlPath = (self.baseURL + self.path) + (key.isEmpty ? "" : ("."+key))
            if let custom = customCache?(res) {
                storage?.async.setObject(custom, forKey: urlPath, completion: { (result) in
                    switch result {
                      case .value:
                        break
                      case .error(let error):
                        print_cd(error)
                    }
                })
            }else{
                storage?.async.setObject(res, forKey: urlPath, completion: { (result) in
                    switch result {
                      case .value:
                        break
                      case .error(let error):
                        print_cd(error)
                    }
                })
            }
        }
        return self
    }
    
    @discardableResult
    func removeCache(withData key:String, completion:((Bool) ->Void)? = nil) -> Self {
        let urlPath = (self.baseURL + self.path) + (key.isEmpty ? "" : ("."+key))
        storage?.async.removeObject(forKey: urlPath, completion: { (result) in
            switch result {
              case .value:
                completion?(true)
              case .error(_):
                completion?(false)
            }
        })
        return self
    }
    
    static func removeAllCacheData(_ completion:((Bool) ->Void)? = nil) {
        storage?.async.removeAll(completion: { result in
            switch result {
              case .value:
                completion?(true)
              case .error(_):
                completion?(false)
            }
        })
    }
}



