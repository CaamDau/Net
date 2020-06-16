//Created  on 2019/6/15 by  LCD:https://github.com/liucaide .

/***** 模块文档 *****
 * Net 的目标是 将 Alamofire 进行基础的二次封装，
 * 追求简洁，小成本，能快速拿来使用，使快速开发的效率提升，快速搭建网络层
 * 后面会计划 实现 Rx 的扩展版本
 *
 */




import Foundation
import Alamofire
import CaamDauExtension

public var net:Net {
    return Net()
}


extension Net {
    public enum RequestStyle {
        case data
        case json
        case string
    }
    
    public struct Error: Swift.Error {
        public let code:Int
        public let massage:String
        public init(code:Int, massage:String) {
            self.code = code
            self.massage = massage.isEmpty ? (Net.Error.massageFor(code) ?? "") : massage
        }
    }
    
    public struct Manager {
        /// 超时时间 默认 10 秒
        public var timeoutInterval:TimeInterval = 10
        /// 默认 header
        public var headers:[String:String] = [:]
        /// 默认w网址
        public var baseURL:String = ""
        /// 开启控制台 print
        public var log:Bool = false
        /// 开启控制台 print
        public var logHandler:((Any?, [String:String]?, [String:Any]?)->Void)? = nil
        /// 返回数据样式 默认 json
        public var responseStyle:Net.RequestStyle = .data
        /// method 默认 get
        public var method:Alamofire.HTTPMethod = .get
        /// encoding 默认 default
        public var encoding:ParameterEncoding = URLEncoding.default
        /// subjoin 增补接口通用参数，默认开启增补
        public var parametersSubjoin:[String:Any] = [:]
        /// 入参前 操作，如参数签名
        public var parametersHandler:(([String:Any]?) -> [String:Any]?)? = nil
    }
    
    public struct UploadParam {
        ///Data数据流
        public var fileData = Data()
        ///文件的FileURL
        public var fileURL:URL?
        ///服务器对应的参数名称
        public var serverName = ""
        ///文件的名称(上传到服务器后，服务器保存的文件名)
        public var filename = ""
        ///文件的MIME类型
        ///(image/png,image/jpg,application/octet-stream/video/mp4等)
        public var mimeType = "image/png"
        ///文件类型
        public var type:Style = .data
        
        public enum Style {
            case data
            case file
        }
        public init(){}
    }
}
extension Net.Error: LocalizedError {
    public var errorDescription: String? {
        return massage
    }
    public var failureReason: String? {
        return nil
    }
    public var recoverySuggestion: String? {
        return nil
    }
    public var helpAnchor: String? {
        return nil
    }
}


open class Net {
    open var method:Alamofire.HTTPMethod = .get
    open var baseURL:String  = ""
    open var path:String  = ""
    open var parameters:[String:Any]?
    open var uploadParameters:[UploadParam] = []
    open var encoding:ParameterEncoding = URLEncoding.default
    open var headers:[String:String]?
    open var timeoutInterval:TimeInterval = 10
    open var log:Bool = false
    open var responseStyle:Net.RequestStyle = .data
    
    open var statusCodes:[Int] = [200]
    open var success:((Any) ->Void)?
    open var failure:((Net.Error) ->Void)?
    open var uploadProgress:Request.ProgressHandler?
    
    open var cache:((Data) ->Void)?
    
    fileprivate var request:Alamofire.DataRequest?
    fileprivate var uploadRequest:Alamofire.UploadRequest?
    
    public static var config:Manager = Manager()
    public init() {
        self.timeoutInterval = Net.config.timeoutInterval
        self.headers = Net.config.headers
        self.baseURL = Net.config.baseURL
        self.log = Net.config.log
        self.responseStyle = Net.config.responseStyle
        self.method = Net.config.method
        self.encoding = Net.config.encoding
    }
}

extension Net {
    func logPrint<T>(_ res:DataResponse<T>) {
        guard log else { return }
        if let logHandler = Net.config.logHandler {
            logHandler(res, headers, parameters)
        }else{
            debugPrint("---👉👉👉", res.request?.url ?? "")
            debugPrint("Headers：", headers ?? "")
            debugPrint("Parameters：", parameters ?? "")
            debugPrint(res.result)
            debugPrint("----------  👻")
        }
    }
    
    func disposeResponse<T>(_ response:DataResponse<T>) {
        logPrint(response)
        switch response.result {
        case .success(let res):
            let statusCode = response.response?.statusCode
            if let code = statusCode, self.statusCodes.contains(code) {
                self.success?(res)
                if let da = res as? Data {
                    self.cache?(da)
                }
            }else{
                self.failure?(Net.Error(code: statusCode ?? -88888, massage: ""))
            }
        case .failure(let error):
            let err = error as NSError
            self.failure?(Net.Error(code: err.code, massage: err.localizedDescription))
        }
    }
    
    func makeCacheData() {
        if (self.cache != nil) {
            request?.responseData { (response) in
                if case let .success(res) = response.result, let code = response.response?.statusCode, self.statusCodes.contains(code)  {
                    self.cache?(res)
                }
            }
        }
    }
    
    func disposeUpload(_ encodingResult:SessionManager.MultipartFormDataEncodingResult) {
        switch encodingResult {
        case .success(let uploads, _, _):
            uploadRequest = uploads
            uploadRequest?.uploadProgress(closure: { (progress) in
                self.uploadProgress?(progress)
            })
            switch responseStyle {
            case .json:
                uploadRequest?.responseJSON { (response) in
                    self.disposeResponse(response)
                }
            case .string:
                uploadRequest?.responseString { (response) in
                    self.disposeResponse(response)
                }
            case .data:
                uploadRequest?.responseData { (response) in
                    self.disposeResponse(response)
                }
            }
        case .failure(let error):
            let err = error as NSError
            self.failure?(Net.Error(code: err.code, massage: err.localizedDescription))
        }
    }
    
    func requestTo() {
        let urlPath = (self.baseURL + self.path)
        request = SessionManager.default.request(urlPath, method: self.method, parameters: self.parameters, encoding: self.encoding, headers: self.headers)
        request?.session.configuration.timeoutIntervalForRequest = timeoutInterval
        request?.session.configuration.timeoutIntervalForResource = timeoutInterval
        switch responseStyle {
        case .json:
            request?.responseJSON { (response) in
                self.disposeResponse(response)
            }
            makeCacheData()
        case .string:
            request?.responseString { (response) in
                self.disposeResponse(response)
            }
            makeCacheData()
        case .data:
            request?.responseData { (response) in
                self.disposeResponse(response)
            }
        }
        
        
    }
    
    /// 上传 MultipartFormData 类型的文件数据，
    func uploadFormData() {
        let url = (self.baseURL + self.path)
        SessionManager.default.upload(multipartFormData: { (formData) in
            for item in self.uploadParameters {
                switch (item.type) {
                case .data:
                    formData.append(item.fileData, withName: item.serverName, fileName: item.filename, mimeType: item.mimeType)
                case .file:
                    if let fileUrl = item.fileURL {
                        formData.append(fileUrl, withName: item.serverName, fileName: item.filename, mimeType: item.mimeType)
                    }
                }
            }
            for item in self.parameters ?? [:] {
                let dat:Data = (item.value as? String)?.data(using: String.Encoding.utf8) ?? Data()
                formData.append(dat, withName: item.key)
            }
        }, to: url,
           headers:headers,
           encodingCompletion: { (encodingResult) in
            self.disposeUpload(encodingResult)
        })
    }
    /// 下载，断线续传能力
}

public extension Net {
    @discardableResult
    func method(_ t:Alamofire.HTTPMethod) -> Self {
        method = t
        return self
    }
    @discardableResult
    func baseURL(_ t:String) -> Self {
        baseURL = t
        return self
    }
    @discardableResult
    func path(_ t:String) -> Self {
        path = t
        return self
    }
    @discardableResult
    func parameters(_ t:[String:Any]?) -> Self {
        parameters = t
        return self
    }
    @discardableResult
    func uploadParameters(_ t:[Net.UploadParam]) -> Self {
        uploadParameters = t
        return self
    }
    
    @discardableResult
    func encoding(_ t:ParameterEncoding) -> Self {
        encoding = t
        return self
    }
    @discardableResult
    func headers(_ t:[String:String]?) -> Self {
        headers = t ?? Net.config.headers
        return self
    }
    @discardableResult
    func timeoutInterval(_ t:TimeInterval) -> Self {
        timeoutInterval = t
        return self
    }
    @discardableResult
    func log(_ t:Bool) -> Self {
        log = t
        return self
    }
    @discardableResult
    func responseStyle(_ t:Net.RequestStyle) -> Self {
        responseStyle = t
        return self
    }
    @discardableResult
    func statusCodes(_ t:[Int]) -> Self {
        statusCodes = t
        return self
    }
    @discardableResult
    func success(_ t:((Any) ->Void)?) -> Self {
        success = t
        return self
    }
    @discardableResult
    func failure(_ t:((Net.Error) ->Void)?) -> Self {
        failure = t
        return self
    }
    @discardableResult
    func uploadProgress(_ t:Request.ProgressHandler?) -> Self {
        uploadProgress = t
        return self
    }
    
    @discardableResult
    func cancel() -> Self {
        request?.cancel()
        uploadRequest?.cancel()
        return self
    }
    
    @discardableResult
    func filter(_ t:() -> Bool) -> Self {
        guard t() else { return self}
        
        return self
    }
    
    /// 发出请求
    /// isSubjoin 是否增补接口通用参数，默认开启增补
    /// handler 参数补充操作，如进行参数签名， 默认使用全局 Net.config.parametersHandler
    @discardableResult
    func request(isSubjoin:Bool = true, handler:(([String:Any]?) -> [String:Any]?)? = Net.config.parametersHandler) -> Self {
        subjoinParameters(isSubjoin, handler)
        requestTo()
        return self
    }
    
    
    
    /// 发出上传请求
    /// isSubjoin 是否增补接口通用参数，默认开启增补
    /// handler 参数补充操作，如进行参数签名， 默认使用全局 Net.config.parametersHandler
    @discardableResult
    func upload(isSubjoin:Bool = true, handler:(([String:Any]?) -> [String:Any]?)? = Net.config.parametersHandler) -> Self {
        subjoinParameters(isSubjoin, handler)
        uploadFormData()
        return self
    }
    
    private func subjoinParameters(_ subjoin:Bool, _ handler:(([String:Any]?) -> [String:Any]?)?) {
        if subjoin, !Net.config.parametersSubjoin.isEmpty {
            var paramet =  parameters ?? [:]
            paramet += Net.config.parametersSubjoin
            parameters = paramet
        }
        parameters = handler?(parameters) ?? parameters
        
    }
}
