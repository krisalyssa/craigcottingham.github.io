#import <Foundation/foundation.h>

// http://stackoverflow.com/questions/586370/how-can-i-reverse-a-nsarray-in-objective-c/586483#586483
@interface NSMutableArray (Reverse)
- (void) reverse;
@end

@implementation NSMutableArray (Reverse)

- (void) reverse
{
    NSUInteger i = 0;
    NSUInteger j = [self count] - 1;
    while (i < j)
    {
        [self exchangeObjectAtIndex: i withObjectAtIndex: j];

        i++;
        j--;
    }
}

@end

NSNumber* next_hailstone(NSNumber* n)
{
    NSUInteger old_val = [n intValue];
    NSUInteger new_val = (old_val % 2) ? (3 * old_val + 1) : (old_val / 2);
    return [NSNumber numberWithInt: new_val];
}

int main(int argc, const char* argv[])
{
    NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];

    NSMutableArray* list = [NSMutableArray array];
    
    NSUInteger i;
    for (i = 0; i < 10000000; ++i)
    {
        [list addObject: [NSNumber numberWithInt: i]];
    }
    
    for (i = 0; i < 5; ++i)
    {
        NSNumber* n = [NSNumber numberWithInt: 13255];
        while ([n intValue] != 1)
        {
            NSNumber* val = [list objectAtIndex: [n intValue]];
            [list removeObjectAtIndex: [n intValue]];
            ([val intValue] % 2) ? [list insertObject: val atIndex: 0] : [list addObject: val];
            n = next_hailstone(n);
        }
        [list reverse];
    }
        
    [pool release];
    return 0;
}
