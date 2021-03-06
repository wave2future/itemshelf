// -*-  Mode:ObjC; c-basic-offset:4; tab-width:8; indent-tabs-mode:nil -*-
/*
  ItemShelf for iPhone/iPod touch

  Copyright (c) 2008, ItemShelf Development Team. All rights reserved.

  Redistribution and use in source and binary forms, with or without
  modification, are permitted provided that the following conditions are
  met:

  1. Redistributions of source code must retain the above copyright notice,
  this list of conditions and the following disclaimer. 

  2. Redistributions in binary form must reproduce the above copyright
  notice, this list of conditions and the following disclaimer in the
  documentation and/or other materials provided with the distribution. 

  3. Neither the name of the project nor the names of its contributors
  may be used to endorse or promote products derived from this software
  without specific prior written permission. 

  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
  "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
  LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
  A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR
  CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
  EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
  PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
  PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
  LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
  NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

#import "Database.h"
#import "AppDelegate.h"
#import "Item.h"
#import "Shelf.h"
#import "DateFormatter2.h"

@implementation dbstmt

@synthesize handle;

/**
   Initialize with sqlite3_stmt
*/
- (id)initWithStmt:(sqlite3_stmt *)st
{
    self = [super init];
    if (self != nil) {
        stmt = st;
    }
    return self;
}

- (void)dealloc
{
    if (stmt) {
        sqlite3_finalize(stmt);
    }
    [super dealloc];
}

/**
   Execute step (sqlite3_step)
*/
- (int)step
{
    int ret = sqlite3_step(stmt);
    if (ret != SQLITE_OK && ret != SQLITE_ROW && ret != SQLITE_DONE) {
        NSLog(@"sqlite3_step error:%d (%s)", ret, sqlite3_errmsg(handle));
    }
    return ret;
}

/**
   Reset statement (sqlite3_reset)
*/
- (void)reset
{
    sqlite3_reset(stmt);
}

/**
   Bind integer value
*/
- (void)bindInt:(int)idx val:(int)val
{
    sqlite3_bind_int(stmt, idx+1, val);
}

/**
   Bind double value
*/
- (void)bindDouble:(int)idx val:(double)val
{
    sqlite3_bind_double(stmt, idx+1, val);
}

/**
   Bind C-string value
*/
- (void)bindCString:(int)idx val:(const char *)val
{
    sqlite3_bind_text(stmt, idx+1, val, -1, SQLITE_TRANSIENT);
}

/**
   Bind stringvalue
*/
- (void)bindString:(int)idx val:(NSString*)val
{
    sqlite3_bind_text(stmt, idx+1, [val UTF8String], -1, SQLITE_TRANSIENT);
}

/**
   Bind date value
*/
- (void)bindDate:(int)idx val:(NSDate*)date
{
    sqlite3_bind_text(stmt, idx+1, [Database cstringFromDate:date], -1, SQLITE_TRANSIENT);
}

/**
   Get integer value
*/
- (int)colInt:(int)idx
{
    return sqlite3_column_int(stmt, idx);
}

/**
   Get double value
*/
- (double)colDouble:(int)idx
{
    return sqlite3_column_double(stmt, idx);
}

/**
   Get C-string value
*/
- (const char *)colCString:(int)idx
{
    const char *s = (const char*)sqlite3_column_text(stmt, idx);
    return s;
}

/**
   Get stringvalue
*/
- (NSString*)colString:(int)idx
{
    const char *s = (const char*)sqlite3_column_text(stmt, idx);
    if (!s) {
        return @"";
    }
    NSString *ns = [NSString stringWithCString:s encoding:NSUTF8StringEncoding];
    return ns;
}

/**
   Get date value
*/
- (NSDate*)colDate:(int)idx
{
    NSDate *date = nil;
    const char *ds = [self colCString:idx];
    if (ds) {
        date = [Database dateFromCString:ds];
    }
    return date;
}

@end


/////////////////////////////////////////////////////////////////////////

@implementation Database

@synthesize handle;

static Database *theDatabase = nil;

static DateFormatter2 *dateFormatter = nil;

/**
   Return the database instance (singleton)
*/
+ (Database *)instance
{
    if (!theDatabase) {
        theDatabase = [[Database alloc] init];
        [theDatabase open];
    }
    return theDatabase;
}

+ (void)shutdown
{
    [theDatabase release];
    theDatabase = nil;

    [dateFormatter release];
    dateFormatter = nil;

    //sqlite3_shutdown();
}

- (id)init
{
    ASSERT(theDatabase == nil);
    self = [super init];
    if (self != nil) {
        handle = 0;

        if (dateFormatter == nil) {
            dateFormatter = [[DateFormatter2 alloc] init];
            [dateFormatter setTimeZone: [NSTimeZone timeZoneWithAbbreviation:@"UTC"]];
            [dateFormatter setDateFormat: @"yyyyMMddHHmm"];
        }
    }
	
    return self;
}

- (void)dealloc
{
    ASSERT(self == theDatabase);
    theDatabase = nil;

    if (handle != nil) {
        sqlite3_close(handle);
    }

    [dateFormatter release];
    dateFormatter = nil;

    [super dealloc];
}

/**
   Execute SQL statement
*/
- (void)exec:(const char *)sql
{
    ASSERT(handle != 0);

    //LOG(@"SQL: %s", sql);
    int result = sqlite3_exec(handle, sql, NULL, NULL, NULL);
    if (result != SQLITE_OK) {
        LOG(@"sqlite3: %s", sqlite3_errmsg(handle));
        ASSERT(0);
    }
}

/**
   Prepare statement

   @param[in] sql SQL statement
   @return dbstmt instance
*/
- (dbstmt *)prepare:(const char *)sql
{
    sqlite3_stmt *stmt;
    int result = sqlite3_prepare_v2(handle, sql, -1, &stmt, NULL);
    if (result != SQLITE_OK) {
        LOG(@"sqlite3: %s", sqlite3_errmsg(handle));
        ASSERT(0);
    }

    dbstmt *dbs = [[[dbstmt alloc] initWithStmt:stmt] autorelease];
    dbs.handle = self.handle;
    return dbs;
}

/**
   Get last inserted row id
*/
- (int)lastInsertRowId
{
    return sqlite3_last_insert_rowid(handle);
}

/**
   Start transaction
*/
- (void)beginTransaction
{
    [self exec:"BEGIN;"];
}

/**
   Commit transaction
*/
- (void)commitTransaction
{
    [self exec:"COMMIT;"];
}

/**
   Return database file name
*/
- (NSString*)dbPath
{
    NSString *dbPath = [AppDelegate pathOfDataFile:@"itemshelf.db"];
    NSLog(@"dbPath = %@", dbPath);

    return dbPath;
}

- (NSString*)_oldDbPath
{
    NSString *oldDbPath = [AppDelegate pathOfDataFile:@"iWantThis.db"];
    NSLog(@"oldDbPath = %@", oldDbPath);

    return oldDbPath;
}

/**
   Open database

   @return Returns YES if database exists, otherwise create database and returns NO.
*/
- (BOOL)open
{
    NSFileManager *fileManager = [NSFileManager defaultManager];

    // Check old DB
    NSString *oldDbPath = [self _oldDbPath];
    BOOL isExistOldDb = [fileManager fileExistsAtPath:oldDbPath];

    // Load from DB
    NSString *dbPath = [self dbPath];
    BOOL isExistedDb = [fileManager fileExistsAtPath:dbPath];

    if (isExistOldDb) {
        if (isExistedDb) {
            [fileManager removeItemAtPath:oldDbPath error:NULL];
        } else {
            [fileManager moveItemAtPath:oldDbPath toPath:dbPath error:NULL];
            isExistedDb = YES;
        }
    }
	
    if (sqlite3_open([dbPath UTF8String], &handle) != 0) {
        // ouch!
        // re-create database
        [fileManager removeItemAtPath:dbPath error:NULL];
        sqlite3_open([dbPath UTF8String], &handle);

        isExistedDb = NO;
    }

    [self checkTables];

    return isExistedDb;
}

/**
   Create / upgrade tables
*/
- (void)checkTables
{
    [Item checkTable];
    [Shelf checkTable];
}

//////////////////////////////////////////////////////////////////////////////////
// Utility

/**
   Generate NSDate from C-string
*/
+ (NSDate*)dateFromCString:(const char *)str
{
    NSDate *date = [dateFormatter dateFromString:
                                      [NSString stringWithCString:str encoding:NSUTF8StringEncoding]];
    return date;
}

/**
   Get C-string from NSDate
*/
+ (const char *)cstringFromDate:(NSDate*)date
{
    const char *s = [[dateFormatter stringFromDate:date] UTF8String];
    return s;
}

@end
