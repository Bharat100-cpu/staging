public with sharing class AccountTriggerHelper {
    
    public static void createPrimaryContactForIndustryAccount(Map<Id,Account> newAccountsMap) {
        AccountContactCreator.createPrimaryContactForIndustryAccount(newAccountsMap);
    }

    public static void insertTask(List<Account> accounts) {
        AccountTaskCreator.insertTask(accounts);
    }

    public static void setRating(List<Account> newAccounts, Map<Id, Account> oldAccounts) {
        AccountRatingHelper.setRating(newAccounts, oldAccounts);
    }

    public static void accountValidationToDelete(List<Account> accounts) {
        AccountDeletionValidator.validateAccountToDelete(accounts);
    }
}