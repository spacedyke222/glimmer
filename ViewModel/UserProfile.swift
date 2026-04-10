import SwiftData
import Foundation

@Model
class UserProfile {
    @Attribute(.unique) var email: String
    var name: String
    var height: Int      // in inches
    var weight: Int      // in pounds
    var mantra: String
    var primaryActivity: String
    var gender: String
    var biologicalSex: String
    var birthday: Date
    
    @Attribute var profilePictureData: Data? = nil
    
    init(email: String,
         name: String,
         height: Int,
         weight: Int,
         mantra: String,
         primaryActivity: String,
         gender: String,
         biologicalSex: String,
         birthday: Date) {
        self.email = email
        self.name = name
        self.height = height
        self.weight = weight
        self.mantra = mantra
        self.primaryActivity = primaryActivity
        self.gender = gender
        self.biologicalSex = biologicalSex
        self.birthday = birthday
    }
}
