public with sharing class offerAdjustment
{
    public static list<Id> prodList = new List<Id>();
    public static Map<String, Offer_Adjustment__mdt> offerAdjustmentAllRecordsData = Offer_Adjustment__mdt.getAll();
    public static Map<String, Object> offerAdjustmentMap = new Map<String, Object>();
    public static DateTime systemCurrentDateTime = DateTime.now();
    @InvocableMethod(label='Update Production JSON' description='Updating Product Json Field automatically')
    // In this method we are getting query based on list of Id which we are getting from flow and storing all the values into map//
    public static void onAfterUpdate(List<Id> productList)
    {
        prodList = productList;
        Map<ID, Product2> products = new Map<ID, Product2>([
        SELECT Id, ProductJSON__c,type__c, subtype__c, Family
        FROM Product2 
        WHERE Id IN :productList ]);
        recheckMethod(products.values()); 
    }
    // Now in this method we itrating the productList and getting ProductJSON__c field and if catalog is there then we are calling another method//
    public static void recheckMethod(List<Product2> productList)
    {
        for (Product2 pdt : productList)
        {
            Map<String, Object> catalogMap = (Map<String, Object>)JSON.deserializeUntyped((String)pdt.get('ProductJSON__c'));
            if (catalogMap.containsKey('catalog'))
            {
                domethod( catalogMap,pdt.subtype__c,pdt.type__c);//from here we are sending the catalog values,product object type and product object subtype 
            }
        }
    }
    // In this method we are putting all the condition for updating our json response which is present in ProductJSON__c field // 
    public static void domethod(Map<String, Object> catalogMap,String productSubType,String productType)
    {
        List<Object> offerList = (List<Object>) catalogMap.get('catalog');
        Map<String, Object> offersMap = new Map<String,Object>();

        if (offerList != null) 
        {
            for (String offerAdjustmentSelectedRecordData : offerAdjustmentAllRecordsData.keySet()) 
            {
                Offer_Adjustment__mdt offerAdjustmentData = offerAdjustmentAllRecordsData.get(offerAdjustmentSelectedRecordData);
                if (offerAdjustmentData != null) 
                {
                    DateTime systemCurrentDateTime = DateTime.now();
                    for (Integer i = 0; i < offerList.size(); i++) 
                    {
                        offersMap = (Map<String, Object>) offerList[i];
                        if (offersMap != null && offersMap.containsKey('offers')) 
                        {
                            List<Object> catalogOffersList = (List<Object>) offersMap.get('offers');
                            if (catalogOffersList != null) 
                            {
                                for (Integer j = 0; j < catalogOffersList.size(); j++) 
                                {
                                    Map<String, Object> catalogOffersMap = (Map<String, Object>) catalogOffersList[j];
                                    if (catalogOffersMap != null && catalogOffersMap.containsKey('id')) 
                                    {
                                        String catalogOfferId = (String) catalogOffersMap.get('id');
                                        System.debug('id'+catalogOfferId);
                                        DateTime metaDataStartDateTime = offerAdjustmentData.Start_Date__c;
                                        DateTime metaDataEndDateTime = offerAdjustmentData.End_Date__c;
                                    
                                        if (productSubType == offerAdjustmentData.Product_Sub_Type__c && offersMap.get('subType') == offerAdjustmentData.Product_Sub_Type__c &&
                                        productType == offerAdjustmentData.Product_Type__c)
                                        {
                                            if(offersMap.get('type') == offerAdjustmentData.Product_Type__c &&
                                            offersMap.get('family') == offerAdjustmentData.Family__c) 
                                            {
                                                String productCodeValues = offerAdjustmentData.Product_Codes_Values__c;
                                                Set<String> includeEligibleOfferAdjustmentIdsList = new Set<String>();
                                                Set<String> excludeEligibleOfferAdjustmentIdsList = new Set<String>();
                                                Set<String> noneEligibleOfferAdjustmentIdsList = new Set<String>();
                                                List<String> productCodeValuesList = new List<String>();
                                                if (productCodeValues != null && productCodeValues != '')
                                                {
                                                    productCodeValuesList = productCodeValues.split(',');
                                                }
                                        
                                                switch on (String.valueOf(offerAdjustmentData.Product_Code_Eligibility__c)) 
                                                {
                                                    when 'Includes' 
                                                    {
                                                        if ((productCodeValuesList.contains(catalogOfferId) &&
                                                        offersMap.get('subType') == offerAdjustmentData.Product_Sub_Type__c &&
                                                        metaDataStartDateTime < systemCurrentDateTime &&
                                                        productSubType == offerAdjustmentData.Product_Sub_Type__c))
                                                        {
                                                                
                                                            List<Object> existingValues = (List<Object>) catalogOffersMap.get('eligibleOfferAdjustmentIds');
                                                            if (existingValues == null) 
                                                            {
                                                                existingValues = new List<Object>();
                                                            }
                                                            includeEligibleOfferAdjustmentIdsList.add(offerAdjustmentData.Offer_Adjustment_Id__c);
                                                            for (String adjustmentId : includeEligibleOfferAdjustmentIdsList) 
                                                            {
                                                                if((metaDataEndDateTime == null) ||
                                                                (metaDataEndDateTime > systemCurrentDateTime))
                                                                {
                                                                    existingValues.add(adjustmentId);
                                                                }
                                                            }
                                                            catalogOffersMap.put('eligibleOfferAdjustmentIds', existingValues);
                                                        }
                                                    }
                                                    when 'Excludes' 
                                                    {
                                                        if (!productCodeValuesList.contains(catalogOfferId) &&
                                                        metaDataStartDateTime < systemCurrentDateTime &&
                                                        productSubType == offerAdjustmentData.Product_Sub_Type__c)
                                                        {
                                                            List<Object> existingValues = (List<Object>) catalogOffersMap.get('eligibleOfferAdjustmentIds');
                                                            if (existingValues == null) 
                                                            {
                                                                existingValues = new List<Object>();
                                                            }
                                                            excludeEligibleOfferAdjustmentIdsList.add(offerAdjustmentData.Offer_Adjustment_Id__c);
                                                            for (String adjustmentId : excludeEligibleOfferAdjustmentIdsList) 
                                                            {
                                                                if((metaDataEndDateTime == null) ||
                                                                (metaDataEndDateTime > systemCurrentDateTime))
                                                                {
                                                                    existingValues.add(adjustmentId);
                                                                }
                                                            }
                                                            catalogOffersMap.put('eligibleOfferAdjustmentIds', existingValues);
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                        // If the product object sub type is null then we called another method //
                                        else if(productSubType == null && 
                                        productType == offerAdjustmentData.Product_Type__c)
                                        {
                                            if(offersMap.get('type') == offerAdjustmentData.Product_Type__c &&
                                            offersMap.get('family') == offerAdjustmentData.Family__c)
                                            {
                                                catalogOffersMap = finalCall(catalogOfferId,offersMap,offerAdjustmentData,catalogOffersMap);
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        // For creating new object in json response based on some criteria //
        for (Product2 productFieldValue : [SELECT Id,type__c, subtype__c, Family FROM Product2 WHERE Id IN :prodList])
        {
            List<Map<String, Object>> offerAdjustmentList = new List<Map<String, Object>>();
            for (String offerAdjustmentsValue : offerAdjustmentAllRecordsData.keySet()) 
            {
                Map<String, Object> offerAdjustmentMap = new Map<String, Object>();
                offerAdjustmentMap.put('adjustmentMethod', offerAdjustmentAllRecordsData.get(offerAdjustmentsValue).adjustmentMethod__c);
                offerAdjustmentMap.put('adjustmentValue', offerAdjustmentAllRecordsData.get(offerAdjustmentsValue).Adjustment_Value__c);
                offerAdjustmentMap.put('chargeType', offerAdjustmentAllRecordsData.get(offerAdjustmentsValue).chargeType__c);
                offerAdjustmentMap.put('concessionType', offerAdjustmentAllRecordsData.get(offerAdjustmentsValue).concessionType__c);
                offerAdjustmentMap.put('manualAdjustmentCode', offerAdjustmentAllRecordsData.get(offerAdjustmentsValue).manualAdjustmentCode__c);
                offerAdjustmentMap.put('manualAdjustmentDescription', offerAdjustmentAllRecordsData.get(offerAdjustmentsValue).manualAdjustmentDescription__c);
                offerAdjustmentMap.put('OfferAdjustmentID', offerAdjustmentAllRecordsData.get(offerAdjustmentsValue).Offer_Adjustment_Id__c);
                offerAdjustmentMap.put('taxStatusOverride', offerAdjustmentAllRecordsData.get(offerAdjustmentsValue).taxStatusOverride__c);

                if ((productFieldValue.get('Family') == offerAdjustmentAllRecordsData.get(offerAdjustmentsValue).Family__c &&
                productFieldValue.get('type__c') == offerAdjustmentAllRecordsData.get(offerAdjustmentsValue).Product_Type__c)) 
                {
                    if (productFieldValue.get('subtype__c') == null)
                    {
                        offerAdjustmentList.add(offerAdjustmentMap);
                        offersMap.put('offerAdjustmentList', offerAdjustmentList);
                    } 
                    else if (productFieldValue.get('subtype__c') != null && 
                    productFieldValue.get('subtype__c') == offerAdjustmentAllRecordsData.get(offerAdjustmentsValue).Product_Sub_Type__c &&
                    offerAdjustmentAllRecordsData.get(offerAdjustmentsValue).Start_Date__c < systemCurrentDateTime) 
                    {
                        offerAdjustmentList.add(offerAdjustmentMap);
                        offersMap.put('offerAdjustmentList', offerAdjustmentList);
                    }
                }
            }
        }
        // When all the conditions are fulfilled then here we are updating ProductJSON__c field in product object
        String finalString = JSON.serialize(catalogMap);
        List<Product2> updatedList = new List<Product2>();
        for (Product2 pdt :[SELECT  Id, ProductJSON__c,type__c, subtype__c, Family FROM Product2 WHERE Id IN :prodList]) 
        {
            if(pdt.Family != null && pdt.type__c != null)
            {
                pdt.ProductJSON__c = finalString;
                updatedList.add(pdt);
            }
        }
        if (!updatedList.isEmpty()) 
        {
            update updatedList;
        }
    }
    // This is another method where we are doing operation when product subtype is null//
    public static Map<String, Object> finalCall(String catalogOfferId,Map<String, Object> offersMap, 
    Offer_Adjustment__mdt offerAdjustmentData, Map<String, Object> catalogOffersMap)
    {
        DateTime metaDataStartDateTime = offerAdjustmentData.Start_Date__c;
        DateTime metaDataEndDateTime = offerAdjustmentData.End_Date__c;
        String productCodeValues = offerAdjustmentData.Product_Codes_Values__c;
        Set<String> includeEligibleOfferAdjustmentIdsList = new Set<String>();
        Set<String> excludeEligibleOfferAdjustmentIdsList = new Set<String>();
        Set<String> noneEligibleOfferAdjustmentIdsList = new Set<String>();
        List<String> productCodeValuesList = new List<String>();
        if (productCodeValues != null && productCodeValues != '')
        {
            productCodeValuesList = productCodeValues.split(',');
        }
        switch on (String.valueOf(offerAdjustmentData.Product_Code_Eligibility__c)) 
        {
            when 'Includes' 
            {
                if ((productCodeValuesList.contains(catalogOfferId) &&
                offersMap.get('subType') == offerAdjustmentData.Product_Sub_Type__c &&
                metaDataStartDateTime < systemCurrentDateTime ))
                {
                List<Object> existingValues = (List<Object>) catalogOffersMap.get('eligibleOfferAdjustmentIds');
                    if (existingValues == null) 
                    {
                        existingValues = new List<Object>();
                    }
                    includeEligibleOfferAdjustmentIdsList.add(offerAdjustmentData.Offer_Adjustment_Id__c);
                    for (String adjustmentId : includeEligibleOfferAdjustmentIdsList) 
                    {
                        if((metaDataEndDateTime == null) ||
                        (metaDataEndDateTime > systemCurrentDateTime))
                        {
                            existingValues.add(adjustmentId);
                        }
                    }
                    catalogOffersMap.put('eligibleOfferAdjustmentIds', existingValues);
                }
            }
            when 'Excludes' 
            {
                if ((!productCodeValuesList.contains(catalogOfferId) &&
                metaDataStartDateTime < systemCurrentDateTime)&&
                offersMap.get('subType') == offerAdjustmentData.Product_Sub_Type__c)
                {
                    List<Object> existingValues = (List<Object>) catalogOffersMap.get('eligibleOfferAdjustmentIds');
                    if (existingValues == null) 
                    {
                        existingValues = new List<Object>();
                    }
                    excludeEligibleOfferAdjustmentIdsList.add(offerAdjustmentData.Offer_Adjustment_Id__c);
                    for (String adjustmentId : excludeEligibleOfferAdjustmentIdsList) 
                    {
                        if((metaDataEndDateTime == null) ||
                        (metaDataEndDateTime > systemCurrentDateTime))
                        {
                            existingValues.add(adjustmentId);
                        }
                    }
                    catalogOffersMap.put('eligibleOfferAdjustmentIds', existingValues);
                }
            }
            when else
            {
                List<Object> existingValues = (List<Object>) catalogOffersMap.get('eligibleOfferAdjustmentIds');
                if (existingValues == null) 
                {
                    existingValues = new List<Object>();
                }
                noneEligibleOfferAdjustmentIdsList.add(offerAdjustmentData.Offer_Adjustment_Id__c);
                for (String adjustmentId : noneEligibleOfferAdjustmentIdsList) 
                {
                    existingValues.add(adjustmentId);
                }
                catalogOffersMap.put('eligibleOfferAdjustmentIds', existingValues);
            }  
        }
        return catalogOffersMap;
    }
}