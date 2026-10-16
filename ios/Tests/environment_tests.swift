import Foundation
@main struct Tests {
 static func main() {
  let cases: [(String?,Bool,String?,Bool,String)] = [
   (nil,false,nil,false,"unknown"),("receipt",false,nil,false,"unknown"),
   ("sandboxReceipt",true,nil,false,"sandbox"),("receipt",true,nil,false,"production"),
   ("other",true,nil,false,"unknown"),(nil,false,"sandbox",false,"sandbox"),
   (nil,false,"production",false,"production"),(nil,false,"xcode",false,"unknown"),
   ("receipt",true,"sandbox",false,"unknown"),("sandboxReceipt",true,"production",false,"unknown"),
   ("sandboxReceipt",true,"sandbox",false,"sandbox"),("receipt",true,"production",false,"production"),
   ("receipt",true,"production",true,"unknown"),
   ("receipt",true,"xcode",false,"unknown"),("sandboxReceipt",true,"unsupported",false,"unknown"),
   (nil,false,"xcode",false,"unknown")]
  for c in cases {
   precondition(EnvironmentDecision.resolve(receiptName:c.0,receiptExists:c.1,verifiedAppEnvironment:c.2,simulator:c.3)==c.4)
  }
  print("16 native environment decision checks PASS; StoreKit not invoked")
 }
}
