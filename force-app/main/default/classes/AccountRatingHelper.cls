public with sharing class AccountRatingHelper {
    
    public static void setRating(List<Account> newAccounts, Map<Id, Account> oldAccounts) {
        for (Account account : newAccounts) {
            if (account.AnnualRevenue != null && shouldUpdateAccountRating(account, oldAccounts)) {
                // Simplify rating logic
                account.Rating = getAccountRating(account.AnnualRevenue);
            }
        }
    }
    
    private static Boolean shouldUpdateAccountRating(Account account, Map<Id, Account> oldAccounts) {
        if (oldAccounts != null && oldAccounts.containsKey(account.Id)) {
            Account oldAccount = oldAccounts.get(account.Id);
            if (account.AnnualRevenue == oldAccount.AnnualRevenue) {
                return false;
            }
        }
        return true;
    }
    
    private static String getAccountRating(Decimal annualRevenue) {
        if (annualRevenue > 1000000) {
            return 'Hot';
        } else if (annualRevenue > 500000) {
            return 'Warm';
        } else if (annualRevenue > 0) {
            return 'Cold';
        } else {
            return '';
        }
    }
}
