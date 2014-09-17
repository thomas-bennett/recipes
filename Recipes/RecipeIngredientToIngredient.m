//
//  RecipeIngredientToIngredient.m
//  Recipes
//
//  Created by Thomas Bennett on 7/16/14.
//  Copyright (c) 2014 Thomas Bennett. All rights reserved.
//

#import "RecipeIngredientToIngredient.h"

@implementation RecipeIngredientToIngredient

-(BOOL)createDestinationInstancesForSourceInstance:(NSManagedObject *)source
                                     entityMapping:(NSEntityMapping *)mapping
                                           manager:(NSMigrationManager *)manager
                                             error:(NSError *__autoreleasing *)error {

    NSMutableDictionary *userInfo = (NSMutableDictionary*)manager.userInfo;
    if (!userInfo) {
        userInfo = [NSMutableDictionary dictionary];
        manager.userInfo = userInfo;
    }
    
    NSMutableDictionary *ingredientLookup = userInfo[@"ingredients"];
    if (!ingredientLookup) {
        ingredientLookup = [NSMutableDictionary dictionary];
        userInfo[@"ingredients"] = ingredientLookup;
    }
    
    NSMutableDictionary *unitOfMeasureLookup = userInfo[@"unitOfMeasure"];
    if (!unitOfMeasureLookup) {
        unitOfMeasureLookup = [NSMutableDictionary dictionary];
        userInfo[@"unitOfMeasure"] = unitOfMeasureLookup;
    }
    
    NSString *name = [source valueForKey:@"name"];
    NSManagedObject *ingredient = ingredientLookup[name];
    if (!ingredient) {
        ingredient = [NSEntityDescription insertNewObjectForEntityForName:mapping.destinationEntityName
                                                   inManagedObjectContext:manager.destinationContext];
        [ingredient setValue:name forKey:@"name"];
        ingredientLookup[name] = ingredient;
        
        name = [source valueForKey:@"unitOfMeasure"];
        NSManagedObject *unitOfMeasure = unitOfMeasureLookup[name];
        if (!unitOfMeasure) {
            unitOfMeasure = [NSEntityDescription insertNewObjectForEntityForName:@"UnitOfMeasure"
                                                          inManagedObjectContext:manager.destinationContext];
            [unitOfMeasure setValue:name forKey:@"name"];
            unitOfMeasureLookup[name] = unitOfMeasure;
        }
        [ingredient setValue:unitOfMeasure forKey:@"unitOfMeasure"];
    }
    
    [manager associateSourceInstance:source withDestinationInstance:ingredient forEntityMapping:mapping];
    return YES;
}

- (BOOL)createRelationshipsForDestinationInstance:(NSManagedObject *)dInstance entityMapping:(NSEntityMapping *)mapping manager:(NSMigrationManager *)manager error:(NSError *__autoreleasing *)error {
    return YES;
}

@end