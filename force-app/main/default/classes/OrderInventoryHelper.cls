public with sharing class OrderInventoryHelper {
    
    private static Boolean isProcessing = false;
    
    public static void processOrderStatusChanges(List<Order> newOrders, Map<Id, Order> oldMap) {
        if (isProcessing) return;
        isProcessing = true;
        
        try {
            Set<Id> orderIds = new Set<Id>();
            for (Order o : newOrders) {
                orderIds.add(o.Id);
            }
            
            Map<Id, List<OrderItem>> orderItemsMap = new Map<Id, List<OrderItem>>();
            for (OrderItem oi : [
                SELECT Id, OrderId, Product2Id, Quantity 
                FROM OrderItem 
                WHERE OrderId IN :orderIds
            ]) {
                if (!orderItemsMap.containsKey(oi.OrderId)) {
                    orderItemsMap.put(oi.OrderId, new List<OrderItem>());
                }
                orderItemsMap.get(oi.OrderId).add(oi);
            }
            
            Set<Id> productIds = new Set<Id>();
            for (List<OrderItem> oiList : orderItemsMap.values()) {
                for (OrderItem oi : oiList) {
                    productIds.add(oi.Product2Id);
                }
            }
            
            Map<Id, Product2> productMap = new Map<Id, Product2>([
                SELECT Id, Available_Inventory__c 
                FROM Product2 
                WHERE Id IN :productIds
            ]);
            
            for (Order o : newOrders) {
                Order oldOrder = oldMap.get(o.Id);
                
                if (oldOrder != null && oldOrder.Status == 'Draft' && o.Status == 'Activated') {
                    List<OrderItem> orderItems = orderItemsMap.get(o.Id);
                    if (orderItems != null) {
                        for (OrderItem oi : orderItems) {
                            Product2 product = productMap.get(oi.Product2Id);
                            if (product != null && product.Available_Inventory__c != null) {
                                if (oi.Quantity > product.Available_Inventory__c) {
                                    o.addError('Insufficient inventory for OrderItem ' + oi.Id + '. Only ' + product.Available_Inventory__c + ' units available.');
                                }
                            }
                        }
                    }
                }
                else if (oldOrder != null && oldOrder.Status == 'Activated' && o.Status == 'Cancelled') {
                }
            }
        } finally {
            isProcessing = false;
        }
    }
    
public static void processOrderStatusChangeAdjustments(List<Order> newOrders, Map<Id, Order> oldMap) {
        if (isProcessing) return;
        isProcessing = true;
        
        try {
            Set<Id> orderIds = new Set<Id>();
            for (Order o : newOrders) {
                orderIds.add(o.Id);
            }
            
            Map<Id, List<OrderItem>> orderItemsMap = new Map<Id, List<OrderItem>>();
            for (OrderItem oi : [
                SELECT Id, OrderId, Product2Id, Quantity 
                FROM OrderItem 
                WHERE OrderId IN :orderIds
            ]) {
                if (!orderItemsMap.containsKey(oi.OrderId)) {
                    orderItemsMap.put(oi.OrderId, new List<OrderItem>());
                }
                orderItemsMap.get(oi.OrderId).add(oi);
            }
            
            Set<Id> productIds = new Set<Id>();
            for (List<OrderItem> oiList : orderItemsMap.values()) {
                for (OrderItem oi : oiList) {
                    productIds.add(oi.Product2Id);
                }
            }
            
            Map<Id, Product2> productMap = new Map<Id, Product2>([
                SELECT Id, Available_Inventory__c 
                FROM Product2 
                WHERE Id IN :productIds
            ]);
            
            // Use a map to track products to update to prevent duplicates
            Map<Id, Product2> productsToUpdate = new Map<Id, Product2>();
            
            for (Order o : newOrders) {
                Order oldOrder = oldMap.get(o.Id);
                
                if (oldOrder != null && oldOrder.Status == 'Draft' && o.Status == 'Activated') {
                    List<OrderItem> orderItems = orderItemsMap.get(o.Id);
                    if (orderItems != null) {
                        for (OrderItem oi : orderItems) {
                            Product2 product = productMap.get(oi.Product2Id);
                            if (product != null) {
                                product.Available_Inventory__c = product.Available_Inventory__c - oi.Quantity;
                                productsToUpdate.put(product.Id, product);
                            }
                        }
                    }
                }
                else if (oldOrder != null && oldOrder.Status == 'Activated' && o.Status == 'Cancelled') {
                    List<OrderItem> orderItems = orderItemsMap.get(o.Id);
                    if (orderItems != null) {
                        for (OrderItem oi : orderItems) {
                            Product2 product = productMap.get(oi.Product2Id);
                            if (product != null) {
                                product.Available_Inventory__c = product.Available_Inventory__c + oi.Quantity;
                                productsToUpdate.put(product.Id, product);
                            }
                        }
                    }
                }
            }
            
            if (!productsToUpdate.isEmpty()) {
                update productsToUpdate.values();
            }
        } finally {
            isProcessing = false;
        }
    }
}
