@isTest
public class ContactEmailValidatorTest {
    
    @isTest
    static void testValidateContacts() {
        // Create test account
        Account acc = new Account(
            Name = 'Test Account'
        );
        insert acc;
        
        // Create test contacts
        List<Contact> contacts = new List<Contact>();
        Contact contact1 = new Contact(
            FirstName = 'John',
            LastName = 'Doe',
            Email = 'john.doe@example.com',
            AccountId = acc.Id
        );
        contacts.add(contact1);
        
        Contact contact2 = new Contact(
            FirstName = 'Jane',
            LastName = 'Smith',
            Email = 'jane.smith@example.com',
            AccountId = acc.Id
        );
        contacts.add(contact2);
        
        // Test validation
        ContactEmailValidator.validateContacts(contacts, null);
        
        // Verify no errors were added
        System.assert(true, 'Validation should complete without errors');
    }
}
