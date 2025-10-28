public with sharing class OrderItemInventoryHelper {
    
    private static Boolean isProcessing = false;
    
    public static void processOrderItemInventory(List<OrderItem> newOrderItems, Map<Id, OrderItem> oldMap) {
        if (isProcessing) return;
        isProcessing = true;
        
        try {
            Set<Id> orderIds = new Set<Id>();
            Map<Id, OrderItem> orderItemMap = new Map<Id, OrderItem>();
            
            for (OrderItem oi : newOrderItems) {
                orderIds.add(oi.OrderId);
                orderItemMap.put(oi.Id, oi);
            }
            
            Map<Id, Order> orderMap = new Map<Id, Order>([
                SELECT Id, Status 
                FROM Order 
                WHERE Id IN :orderIds
            ]);
            
            Set<Id> productIds = new Set<Id>();
            for (OrderItem oi : newOrderItems) {
                productIds.add(oi.Product2Id);
            }
            
            Map<Id, Product2> productMap = new Map<Id, Product2>([
                SELECT Id, Available_Inventory__c 
                FROM Product2 
                WHERE Id IN :productIds
            ]);
            
            for (OrderItem oi : newOrderItems) {
                Order order = orderMap.get(oi.OrderId);
                Product2 product = productMap.get(oi.Product2Id);
                
                if (order != null && order.Status == 'Activated') {
                    if (Trigger.isInsert) {
                        if (product != null && product.Available_Inventory__c != null) {
                            if (oi.Quantity > product.Available_Inventory__c) {
                                oi.addError('Insufficient inventory. Only ' + product.Available_Inventory__c + ' units available.');
                            }
                        }
                    }
                    else if (Trigger.isUpdate) {
                        OrderItem oldOi = oldMap.get(oi.Id);
                        if (oldOi != null && oldOi.Quantity != oi.Quantity) {
                            Integer quantityDiff = (Integer)oi.Quantity - (Integer)oldOi.Quantity;
                            
                            if (quantityDiff > 0) {
                                if (product != null && product.Available_Inventory__c != null) {
                                    if (quantityDiff > product.Available_Inventory__c) {
                                        oi.addError('Insufficient inventory. Only ' + product.Available_Inventory__c + ' units available.');
                                    }
                                }
                            }
                        }
                    }
                }
            }
        } finally {
            isProcessing = false;
        }
    }
    
public static void processOrderItemInventoryAdjustments(List<OrderItem> newOrderItems, Map<Id, OrderItem> oldMap) {
        if (isProcessing) return;
        isProcessing = true;
        
        try {
            Set<Id> orderIds = new Set<Id>();
            Map<Id, OrderItem> orderItemMap = new Map<Id, OrderItem>();
            
            for (OrderItem oi : newOrderItems) {
                orderIds.add(oi.OrderId);
                orderItemMap.put(oi.Id, oi);
            }
            
            Map<Id, Order> orderMap = new Map<Id, Order>([
                SELECT Id, Status 
                FROM Order 
                WHERE Id IN :orderIds
            ]);
            
            Set<Id> productIds = new Set<Id>();
            for (OrderItem oi : newOrderItems) {
                productIds.add(oi.Product2Id);
            }
            
            Map<Id, Product2> productMap = new Map<Id, Product2>([
                SELECT Id, Available_Inventory__c 
                FROM Product2 
                WHERE Id IN :productIds
            ]);
            
            // Use a map to track products to update to prevent duplicates
            Map<Id, Product2> productsToUpdate = new Map<Id, Product2>();
            
            for (OrderItem oi : newOrderItems) {
                Order order = orderMap.get(oi.OrderId);
                Product2 product = productMap.get(oi.Product2Id);
                
                if (order != null) {
                    if (Trigger.isInsert) {
                        if (order.Status == 'Activated' && product != null) {
                            product.Available_Inventory__c = product.Available_Inventory__c - oi.Quantity;
                            productsToUpdate.put(product.Id, product);
                        }
                    }
                    else if (Trigger.isUpdate) {
                        OrderItem oldOi = oldMap.get(oi.Id);
                        if (oldOi != null) {
                            if (order.Status == 'Activated' && oldOi.OrderId != oi.OrderId) {
                                Order oldOrder = orderMap.get(oldOi.OrderId);
                                if (oldOrder != null && oldOrder.Status == 'Activated' && product != null) {
                                    product.Available_Inventory__c = product.Available_Inventory__c + oldOi.Quantity;
                                    productsToUpdate.put(product.Id, product);
                                }
                                
                                if (order.Status == 'Activated' && product != null) {
                                    product.Available_Inventory__c = product.Available_Inventory__c - oi.Quantity;
                                    productsToUpdate.put(product.Id, product);
                                }
                            }
                            else if (order.Status == 'Activated' && oldOi.Quantity != oi.Quantity && product != null) {
                                Integer quantityDiff = (Integer)oi.Quantity - (Integer)oldOi.Quantity;
                                product.Available_Inventory__c = product.Available_Inventory__c - quantityDiff;
                                productsToUpdate.put(product.Id, product);
                            }
                        }
                    }
                    else if (Trigger.isDelete && order.Status == 'Activated' && product != null) {
                        product.Available_Inventory__c = product.Available_Inventory__c + oi.Quantity;
                        productsToUpdate.put(product.Id, product);
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
