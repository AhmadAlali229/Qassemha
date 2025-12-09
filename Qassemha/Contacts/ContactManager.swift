//
//  ContactManager.swift
//  Qassemha
//
//  Contact management with dummy data integration
//

import SwiftUI
import CoreData

class ContactManager: ObservableObject {
    static let shared = ContactManager()
    private let context = PersistenceController.shared.container.viewContext

    @Published var contacts: [Contact] = []

    private init() {
        initializeDummyContactsIfNeeded()
        fetchContacts()
    }

    // MARK: - Fetch Contacts
    /// Fetches all contacts from Core Data sorted alphabetically by name
    /// Updates the published contacts array for UI binding
    func fetchContacts() {
        let request: NSFetchRequest<Contact> = Contact.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Contact.name, ascending: true)]

        do {
            contacts = try context.fetch(request)
        } catch {
            print("Error fetching contacts: \(error)")
        }
    }

    // MARK: - Initialize Dummy Contacts
    /// Checks if contacts exist and creates dummy data if database is empty
    /// Provides sample contacts for testing and demonstration purposes
    func initializeDummyContactsIfNeeded() {
        let request: NSFetchRequest<Contact> = Contact.fetchRequest()

        do {
            let count = try context.count(for: request)
            if count == 0 {
                createDummyContacts()
            }
        } catch {
            print("Error checking contacts: \(error)")
        }
    }

    private func createDummyContacts() {
        let dummyData = [
            ("Alex Johnson", "alex.j@email.com", "+1234567890"),
            ("Sarah Williams", "sarah.w@email.com", "+1234567891"),
            ("Mike Chen", "mike.c@email.com", "+1234567892"),
            ("Emma Davis", "emma.d@email.com", "+1234567893"),
            ("Jordan Taylor", "jordan.t@email.com", "+1234567894"),
            ("Chris Martinez", "chris.m@email.com", "+1234567895"),
            ("Sam Brown", "sam.b@email.com", "+1234567896"),
            ("Lisa Anderson", "lisa.a@email.com", "+1234567897"),
            ("Tom Wilson", "tom.w@email.com", "+1234567898"),
            ("Maya Patel", "maya.p@email.com", "+1234567899"),
            ("Ryan Garcia", "ryan.g@email.com", "+1234567800"),
            ("Oliver Smith", "oliver.s@email.com", "+1234567801"),
            ("Jake Thompson", "jake.t@email.com", "+1234567802"),
            ("Emily Lee", "emily.l@email.com", "+1234567803"),
            ("Daniel Kim", "daniel.k@email.com", "+1234567804"),
            ("Sophie Brown", "sophie.b@email.com", "+1234567805"),
            ("James Wilson", "james.w@email.com", "+1234567806"),
            ("Olivia Martinez", "olivia.m@email.com", "+1234567807"),
            ("Lucas Anderson", "lucas.a@email.com", "+1234567808"),
            ("Ava Robinson", "ava.r@email.com", "+1234567809")
        ]

        for (name, email, phone) in dummyData {
            let contact = Contact(context: context)
            contact.contactID = UUID()
            contact.name = name
            contact.email = email
            contact.phoneNumber = phone
            contact.createdAt = Date()

            // Generate a simple profile image with initials
            if let imageData = generateProfileImage(for: name) {
                contact.profileImageData = imageData
            }
        }

        saveContext()
    }

    // MARK: - Create Contact
    /// Creates a new contact with provided information and optional profile image
    /// Generates default profile image with initials if no image provided
    func createContact(name: String, email: String?, phoneNumber: String?, profileImage: UIImage?) {
        let contact = Contact(context: context)
        contact.contactID = UUID()
        contact.name = name
        contact.email = email
        contact.phoneNumber = phoneNumber
        contact.createdAt = Date()

        if let image = profileImage, let imageData = image.jpegData(compressionQuality: 0.8) {
            contact.profileImageData = imageData
        } else if let imageData = generateProfileImage(for: name) {
            contact.profileImageData = imageData
        }

        saveContext()
        fetchContacts()
    }

    // MARK: - Update Contact
    /// Updates existing contact with new information
    /// Preserves existing profile image if no new image provided
    func updateContact(_ contact: Contact, name: String, email: String?, phoneNumber: String?, profileImage: UIImage?) {
        contact.name = name
        contact.email = email
        contact.phoneNumber = phoneNumber

        if let image = profileImage, let imageData = image.jpegData(compressionQuality: 0.8) {
            contact.profileImageData = imageData
        }

        saveContext()
        fetchContacts()
    }

    // MARK: - Delete Contact
    /// Permanently removes a contact from the database
    /// Updates UI by refetching contact list after deletion
    func deleteContact(_ contact: Contact) {
        context.delete(contact)
        saveContext()
        fetchContacts()
    }

    // MARK: - Search Contacts
    /// Searches contacts by name, email, or phone number
    /// Returns all contacts if query is empty for performance
    func searchContacts(query: String) -> [Contact] {
        if query.isEmpty {
            return contacts
        }

        return contacts.filter { contact in
            contact.name?.localizedCaseInsensitiveContains(query) == true ||
            contact.email?.localizedCaseInsensitiveContains(query) == true ||
            contact.phoneNumber?.localizedCaseInsensitiveContains(query) == true
        }
    }

    // MARK: - Helper Methods
    private func saveContext() {
        do {
            try context.save()
        } catch {
            print("Error saving context: \(error)")
        }
    }

    /// Generates a circular profile image with initials and random color
    /// Creates visually distinct avatars for contacts without photos
    private func generateProfileImage(for name: String) -> Data? {
        let initials = getInitials(from: name)
        let size = CGSize(width: 100, height: 100)
        let colors: [UIColor] = [
            .systemBlue, .systemPurple, .systemOrange, .systemGreen,
            .systemRed, .systemPink, .systemIndigo, .systemTeal
        ]
        let color = colors[abs(name.hashValue) % colors.count]

        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { ctx in
            // Background
            color.setFill()
            ctx.cgContext.fillEllipse(in: CGRect(origin: .zero, size: size))

            // Text
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.alignment = .center

            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 40, weight: .medium),
                .foregroundColor: UIColor.white,
                .paragraphStyle: paragraphStyle
            ]

            let textSize = initials.size(withAttributes: attributes)
            let textRect = CGRect(
                x: (size.width - textSize.width) / 2,
                y: (size.height - textSize.height) / 2,
                width: textSize.width,
                height: textSize.height
            )

            initials.draw(in: textRect, withAttributes: attributes)
        }

        return image.jpegData(compressionQuality: 0.8)
    }

    /// Extracts up to two initials from a name
    /// Takes first character from first two words for display
    private func getInitials(from name: String) -> String {
        let components = name.split(separator: " ")
        let initials = components.prefix(2).compactMap { $0.first }.map { String($0) }
        return initials.joined().uppercased()
    }
}

// MARK: - Contact Extension for UI
extension Contact {
    /// Converts stored profile image data to UIImage
    /// Returns nil if no image data exists
    var profileImage: UIImage? {
        guard let data = profileImageData else { return nil }
        return UIImage(data: data)
    }

    /// Returns contact name or placeholder text
    /// Provides fallback for contacts without names
    var displayName: String {
        name ?? "Unknown"
    }
}
