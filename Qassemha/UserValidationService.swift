//
//  UserValidationService.swift
//  Qassemha
//
//  Created by Harjot Singh on 23/09/25.
//

import Foundation
import CoreData

class UserValidationService {
    static let shared = UserValidationService()

    private init() {}

    func validateUser(email: String? = nil, phoneNumber: String? = nil, password: String, context: NSManagedObjectContext) -> User? {
        let request: NSFetchRequest<User> = User.fetchRequest()

        var predicates: [NSPredicate] = []

        if let email = email {
            let cleanEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            predicates.append(NSPredicate(format: "email == %@ AND password == %@", cleanEmail, password))
        }

        if let phoneNumber = phoneNumber {
            predicates.append(NSPredicate(format: "phoneNumber == %@ AND password == %@", phoneNumber, password))
        }

        if predicates.isEmpty {
            return nil
        }

        request.predicate = NSCompoundPredicate(orPredicateWithSubpredicates: predicates)
        request.fetchLimit = 1

        do {
            let users = try context.fetch(request)
            return users.first
        } catch {
            print("Failed to fetch user: \(error.localizedDescription)")
            return nil
        }
    }

    func findUser(email: String? = nil, phoneNumber: String? = nil, context: NSManagedObjectContext) -> User? {
        let request: NSFetchRequest<User> = User.fetchRequest()

        var predicates: [NSPredicate] = []

        if let email = email {
            let cleanEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            predicates.append(NSPredicate(format: "email == %@", cleanEmail))
        }

        if let phoneNumber = phoneNumber {
            predicates.append(NSPredicate(format: "phoneNumber == %@", phoneNumber))
        }

        if predicates.isEmpty {
            return nil
        }

        request.predicate = NSCompoundPredicate(orPredicateWithSubpredicates: predicates)
        request.fetchLimit = 1

        do {
            let users = try context.fetch(request)
            return users.first
        } catch {
            print("Failed to fetch user: \(error.localizedDescription)")
            return nil
        }
    }

    func getAllUsers(context: NSManagedObjectContext) -> [User] {
        let request: NSFetchRequest<User> = User.fetchRequest()

        do {
            let users = try context.fetch(request)
            return users
        } catch {
            print("Failed to fetch users: \(error.localizedDescription)")
            return []
        }
    }

    func updateUserPassword(user: User, newPassword: String, context: NSManagedObjectContext) -> Bool {
        user.password = newPassword

        do {
            try context.save()
            print("Password updated successfully for user: \(user.email)")
            return true
        } catch {
            print("Failed to update password: \(error.localizedDescription)")
            return false
        }
    }

    func createUser(email: String, phoneNumber: String, fullName: String, password: String, context: NSManagedObjectContext) -> User? {
        // Check if user already exists
        if findUser(email: email, context: context) != nil {
            print("User with email \(email) already exists")
            return nil
        }

        let user = User(context: context)
        user.userID = UUID()
        user.email = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        user.phoneNumber = phoneNumber
        user.fullName = fullName
        user.password = password
        user.createdAt = Date()

        do {
            try context.save()
            print("User created successfully: \(user.email)")
            return user
        } catch {
            print("Failed to create user: \(error.localizedDescription)")
            return nil
        }
    }
}