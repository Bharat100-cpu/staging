public with sharing class ContactController {
    
    @AuraEnabled
    public static Contact createContact(ContactData contactData) {
        Contact contact = new Contact(
            FirstName = contactData.firstName,
            LastName = contactData.lastName,
            Email = contactData.email,
            Phone = contactData.phone
        );
        
        insert contact;
        
        return contact;
    }
    
    // Inner class to hold contact data
    public class ContactData {
        @AuraEnabled public String firstName;
        @AuraEnabled public String lastName;
        @AuraEnabled public String email;
        @AuraEnabled public String phone;
    }
}
