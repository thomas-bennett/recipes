//
//  AppDelegate.m
//  Recipes
//
//  Created by Thomas Bennett on 7/11/14.
//  Copyright (c) 2014 Thomas Bennett. All rights reserved.
//

#import "AppDelegate.h"

@interface AppDelegate ()
            
@property (weak) IBOutlet NSWindow *window;
@property (weak) IBOutlet NSArrayController *recipeArrayController;


- (IBAction)saveAction:(id)sender;
- (IBAction)addImage:(id)sender;

@end

@implementation AppDelegate
            
- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // Insert code here to initialize your application
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}

@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize managedObjectContext = _managedObjectContext;

// Returns the directory the application uses to store the Core Data store file. This code uses a directory named "Thomas-Bennett.Recipes" in the user's Application Support directory.
- (NSURL *)applicationFilesDirectory
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSURL *appSupportURL = [[fileManager URLsForDirectory:NSApplicationSupportDirectory inDomains:NSUserDomainMask] lastObject];
    return [appSupportURL URLByAppendingPathComponent:@"Thomas-Bennett.Recipes"];
}

// Creates if necessary and returns the managed object model for the application.
- (NSManagedObjectModel *)managedObjectModel
{
    if (_managedObjectModel) {
        return _managedObjectModel;
    }
	
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"Recipes" withExtension:@"momd"];
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return _managedObjectModel;
}

// Returns the persistent store coordinator for the application. This implementation creates and return a coordinator, having added the store for the application to it. (The directory for the store is created, if necessary.)
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    if (_persistentStoreCoordinator) {
        return _persistentStoreCoordinator;
    }
    
    NSManagedObjectModel *mom = [self managedObjectModel];
    if (!mom) {
        NSLog(@"%@:%@ No model to generate a store from", [self class], NSStringFromSelector(_cmd));
        return nil;
    }
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSURL *applicationFilesDirectory = [self applicationFilesDirectory];
    NSError *error = nil;
    
    NSDictionary *properties = [applicationFilesDirectory resourceValuesForKeys:@[NSURLIsDirectoryKey] error:&error];
    
    if (!properties) {
        BOOL ok = NO;
        if ([error code] == NSFileReadNoSuchFileError) {
            ok = [fileManager createDirectoryAtPath:[applicationFilesDirectory path] withIntermediateDirectories:YES attributes:nil error:&error];
        }
        if (!ok) {
            [[NSApplication sharedApplication] presentError:error];
            return nil;
        }
    } else {
        if (![properties[NSURLIsDirectoryKey] boolValue]) {
            // Customize and localize this error.
            NSString *failureDescription = [NSString stringWithFormat:@"Expected a folder to store application data, found a file (%@).", [applicationFilesDirectory path]];
            
            NSMutableDictionary *dict = [NSMutableDictionary dictionary];
            [dict setValue:failureDescription forKey:NSLocalizedDescriptionKey];
            error = [NSError errorWithDomain:@"YOUR_ERROR_DOMAIN" code:101 userInfo:dict];
            
            [[NSApplication sharedApplication] presentError:error];
            return nil;
        }
    }
    
    NSURL *url = [applicationFilesDirectory URLByAppendingPathComponent:@"Recipes.storedata"];
    NSPersistentStoreCoordinator *coordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:mom];
    NSDictionary *options = @{NSMigratePersistentStoresAutomaticallyOption:@YES};
    if (![coordinator addPersistentStoreWithType:NSXMLStoreType configuration:nil URL:url options:options error:&error]) {

        NSLog(@"%@:%s %@", [self class], _cmd, error.localizedDescription);
        for (NSError *suberror in [error.userInfo valueForKey:NSDetailedErrorsKey]) {
            NSLog(@"\t%@", suberror.localizedDescription);
        }
        
        NSAlert *alert = [[NSAlert alloc] init];
        alert.alertStyle = NSCriticalAlertStyle;
        alert.messageText = @"Unable to load the recipes database";
        alert.informativeText = [NSString stringWithFormat:@"The recipes database %@%@%@\n%@",
                                 @"is either corrupt or was created by a newer ",
                                 @"version of Grokking Recipes. Please contact ",
                                 @"support to asssist with this error.\n\nError: ",
                                 error.localizedDescription];
        [alert addButtonWithTitle:@"Quit"];
        [alert runModal];
        exit(1);
    }
    _persistentStoreCoordinator = coordinator;
    
    return _persistentStoreCoordinator;
}

// Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.) 
- (NSManagedObjectContext *)managedObjectContext
{
    if (_managedObjectContext) {
        return _managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (!coordinator) {
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        [dict setValue:@"Failed to initialize the store" forKey:NSLocalizedDescriptionKey];
        [dict setValue:@"There was an error building up the data file." forKey:NSLocalizedFailureReasonErrorKey];
        NSError *error = [NSError errorWithDomain:@"YOUR_ERROR_DOMAIN" code:9999 userInfo:dict];
        [[NSApplication sharedApplication] presentError:error];
        return nil;
    }
    _managedObjectContext = [[NSManagedObjectContext alloc] init];
    [_managedObjectContext setPersistentStoreCoordinator:coordinator];
    
    // Special initialization.
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"Type"];
    NSError *error = nil;
    NSArray *result = [_managedObjectContext executeFetchRequest:fetchRequest error:&error];
    NSAssert(error == nil, [error localizedDescription]);
    
    if (result.count) return _managedObjectContext;
    
    // Table hasn't been populated.
    NSArray *types = [[[NSBundle mainBundle] infoDictionary] valueForKey:@"RecipeTypes"];
    for (NSString *type in types) {
        NSManagedObject *object = [NSEntityDescription insertNewObjectForEntityForName:@"Type" inManagedObjectContext:_managedObjectContext];
        [object setValue:type forKey:@"name"];
    }

    return _managedObjectContext;
}

// Returns the NSUndoManager for the application. In this case, the manager returned is that of the managed object context for the application.
- (NSUndoManager *)windowWillReturnUndoManager:(NSWindow *)window
{
    return [[self managedObjectContext] undoManager];
}

// Performs the save action for the application, which is to send the save: message to the application's managed object context. Any encountered errors are presented to the user.
- (IBAction)saveAction:(id)sender
{
    NSError *error = nil;
    
    if (![[self managedObjectContext] commitEditing]) {
        NSLog(@"%@:%@ unable to commit editing before saving", [self class], NSStringFromSelector(_cmd));
    }
    
    if (![[self managedObjectContext] save:&error]) {
        [[NSApplication sharedApplication] presentError:error];
    }
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender
{
    // Save changes in the application's managed object context before the application terminates.
    
    if (!_managedObjectContext) {
        return NSTerminateNow;
    }
    
    if (![[self managedObjectContext] commitEditing]) {
        NSLog(@"%@:%@ unable to commit editing to terminate", [self class], NSStringFromSelector(_cmd));
        return NSTerminateCancel;
    }
    
    if (![[self managedObjectContext] hasChanges]) {
        return NSTerminateNow;
    }
    
    NSError *error = nil;
    if (![[self managedObjectContext] save:&error]) {

        // Customize this code block to include application-specific recovery steps.              
        BOOL result = [sender presentError:error];
        if (result) {
            return NSTerminateCancel;
        }

        NSString *question = NSLocalizedString(@"Could not save changes while quitting. Quit anyway?", @"Quit without saves error question message");
        NSString *info = NSLocalizedString(@"Quitting now will lose any changes you have made since the last successful save", @"Quit without saves error question info");
        NSString *quitButton = NSLocalizedString(@"Quit anyway", @"Quit anyway button title");
        NSString *cancelButton = NSLocalizedString(@"Cancel", @"Cancel button title");
        NSAlert *alert = [[NSAlert alloc] init];
        [alert setMessageText:question];
        [alert setInformativeText:info];
        [alert addButtonWithTitle:quitButton];
        [alert addButtonWithTitle:cancelButton];

        NSInteger answer = [alert runModal];
        
        if (answer == NSAlertFirstButtonReturn) {
            return NSTerminateCancel;
        }
    }

    return NSTerminateNow;
}


- (void)addImage:(id)sender {
    id recipe = [self.recipeArrayController.selectedObjects lastObject];
    if (!recipe) return;
    
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    openPanel.canChooseDirectories = NO;
    openPanel.canCreateDirectories = NO;
    openPanel.allowsMultipleSelection = NO;
    
    [openPanel beginSheetModalForWindow:self.window completionHandler:^(NSInteger result) {
        if (result == NSFileHandlingPanelCancelButton) return;
        NSURL *path = [openPanel.URLs lastObject];
        
        // Build the path we want the file to be at
        NSString *guid = [[NSProcessInfo processInfo] globallyUniqueString];
        NSURL *destPath = [[self applicationFilesDirectory] URLByAppendingPathComponent:guid];

        NSError *error = nil;
        [[NSFileManager defaultManager] copyItemAtURL:path toURL:destPath error:&error];
        if (error) {
            [NSApp presentError:error];
        }
        [recipe setValue:destPath forKey:@"imagePath"];
    }];
}

- (NSArray*)retrieveBigMeals {
    NSFetchRequest *fetchRequest = [self.managedObjectModel fetchRequestTemplateForName:@"bigMeals"];
    NSError *error = nil;
    NSArray *result = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
    if (error) {
        [NSApp presentError:error];
        return nil;
    }
    return result;
}

- (NSArray *)allRecipesSortedByName {
    NSSortDescriptor *nameSort = [[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES];
    NSArray *sorters = @[nameSort];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    fetchRequest.sortDescriptors = sorters;
    fetchRequest.entity = [NSEntityDescription entityForName:@"Recipe" inManagedObjectContext:self.managedObjectContext];
    
    NSError *error = nil;
    NSArray *result = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
    if (error) {
        [NSApp presentError:error];
        return nil;
    }
    
    return result;
}
@end
