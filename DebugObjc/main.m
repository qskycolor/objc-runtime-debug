//
//  main.m
//  DebugObjc
//
//  Created by sky on 2017/4/17.
//
//

#import <Foundation/Foundation.h>
#import "objc/runtime.h"

@protocol ActionProtocol <NSObject>

- (void)walk;
- (void)run;

@end

@protocol ThinkProtocol <NSObject>

- (void)randomThink;
- (void)strictThink;

@end

@interface Person : NSObject<ActionProtocol, ThinkProtocol> {
    __strong id ivar0;
    __strong id ivar1;
    __weak id ivar2;
    __weak id ivar3;
}

@property(nonatomic, assign)int year;
@property(nonatomic, assign)int number;
@property(nonatomic, strong, getter=estimate)NSArray *houses;
@property(nonatomic, copy)NSString *name;
@property(nonatomic, weak)Person *child;
@property(nonatomic, assign)char grade;

- (void)printInfo:(NSString *)info;

@end


@implementation Person

+ (instancetype)instance {
    static Person *sharedInstance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[Person alloc]init];
    });
    return sharedInstance;
}

- (void)printInfo:(NSString *)info {
    NSLog(@"info: %@", info);
}

#pragma mark - ActionProtocol

- (void)run {
    NSLog(@"Person can run！");
}

- (void)walk {
    NSLog(@"Person can walk！");
}

#pragma mark - ThinkProtocol

- (void)randomThink {
    NSLog(@"Person can random think！");
}

- (void)strictThink {
    NSLog(@"Person can strict think！");
}

@end


@interface God : NSObject

- (void)speak;

@end

@implementation God

- (void)speak{
    NSLog(@"God speak!");
}

- (void)output {
    NSLog(@"God output!");
}

@end

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        
        Person *person = [[Person alloc]init];
        Class personClass = object_getClass(person);
        NSLog(@"person: %@", NSStringFromClass(personClass));
        const char *className = class_getName(personClass);
        Class superName = class_getSuperclass(personClass);
        Class metaClass = objc_getMetaClass("Person");
        NSLog(@"classname: %s, superclass: %@, metaClass: %@", className, superName, metaClass);
        BOOL isMetaClass = class_isMetaClass(personClass);
        NSLog(@"isMetaclass: %d, metaClass: %d", isMetaClass, class_isMetaClass(metaClass));
        size_t instanceSize = class_getInstanceSize(personClass);
        NSLog(@"instance size: %lu", instanceSize); // 80
        Ivar var = class_getInstanceVariable(personClass, "_year");// 获取类的实例变量
        /* oc中没有类变量，内部实现是：class_getInstanceVariable(cls->ISA(), name)
           这里可能是指metaClass，只有isa这一个类变量
         */
        //Ivar var = class_getClassVariable(personClass, "isa");// 获取类的类变量
        const char *varName = ivar_getName(var);// 以'_'的实例变量名称
        const char *varEncoding = ivar_getTypeEncoding(var);//typeEncoding
        ptrdiff_t varOffset = ivar_getOffset(var);// 偏移量
        // print: variable name: _year, typeEncoding: i, offset: 44
        NSLog(@"variable name: %s, typeEncoding: %s, offset: %ld", varName, varEncoding, varOffset);
        const uint8_t *layout = class_getIvarLayout(personClass);// 这是什么鬼？
        while (*layout != 0x0 ) {
            NSLog(@"ivar layout: 0x%02x", *layout++); // 0x02 0x42
        }
        const uint8_t *weakLayout = class_getWeakIvarLayout(personClass);
        while (*weakLayout != 0x0 ) {
            NSLog(@"ivar weaklayout: 0x%02x", *weakLayout++); // 0x22 0x41
        }
        NSLog(@"===================Ivar=======================");
        unsigned int ivarCount;
        Ivar *ivarList = class_copyIvarList(personClass, &ivarCount);
        for (unsigned int i = 0; i < ivarCount; i++) {
            Ivar varItem = ivarList[i];
            NSLog(@"ivars %d-> name: %s, encoding: %s, offset: %ld", (i + 1), ivar_getName(varItem), ivar_getTypeEncoding(varItem), ivar_getOffset(varItem));
        }
        // add ivar to person class
        BOOL success = class_addIvar(personClass, "address", sizeof(NSString *), log2(sizeof(NSString *)), "@");
        NSLog(@"addIvar success: %d", success);
        NSLog(@"===================property=======================");
        /// property
        unsigned int propertyCount;
        objc_property_t *properties = class_copyPropertyList(personClass, &propertyCount);
        for (unsigned int i = 0;i < propertyCount;i++) {
            objc_property_t property = properties[i];
            const char *name = property_getName(property);
            const char *attributes = property_getAttributes(property);
            char *attributeValue = property_copyAttributeValue(property, "T");
            /* print:
                1 property: year, attributes: Ti,N,V_year, value: i
                2 property: number, attributes: Ti,N,V_number, value: i
                3 property: houses, attributes: T@"NSArray",&,N,Gestimate,V_houses, value: @"NSArray"
                4 property: name, attributes: T@"NSString",C,N,V_name, value: @"NSString"
                5 property: child, attributes: T@"Person",W,N,V_child, value: @"Person"
                6 property: grade, attributes: Tc,N,V_grade, value: c
            */
            NSLog(@"%u property: %s, attributes: %s, value: %s", (i + 1), name, attributes, attributeValue);
            free(attributeValue);
        }
        free(properties);
        objc_property_t property = class_getProperty(personClass, "child");
        unsigned int attributeCount;
        objc_property_attribute_t *attributeList = property_copyAttributeList(property, &attributeCount);
        for (unsigned int i = 0; i < attributeCount; i++) {
            objc_property_attribute_t attribute = attributeList[i];
            char *value = property_copyAttributeValue(property, attribute.name);
            NSLog(@"attributes-> name: %s, value: %s, copyValue: %s", attribute.name, attribute.value, value);
            free(value);
        }
        free(attributeList);
        NSLog(@"===================Method=======================");
        Method classMethod = class_getClassMethod(personClass, @selector(instance));
        NSLog(@"class method-> name: %s", sel_getName(method_getName(classMethod)));
        Method instanceMethod = class_getInstanceMethod(personClass, @selector(setName:));
        NSLog(@"instance method-> name: %@", NSStringFromSelector(method_getName(instanceMethod)));
        unsigned int methodCount;
        Method *methodList = class_copyMethodList(personClass, &methodCount);
        for (unsigned int i = 0; i < methodCount; i++) {
            Method method = methodList[i];
            SEL selector = method_getName(method);
            //const char *methodName = sel_getName(selector);
            NSString *methodName = NSStringFromSelector(selector);
            NSLog(@"method-> name: %@, description: %s, returnType: %s", methodName, method_getDescription(method)->types, method_copyReturnType(method));
            int argumentCount = method_getNumberOfArguments(method);
            if (argumentCount <= 2 && ![methodName containsString:@"child"] && ![methodName hasPrefix:@"."]) {
                IMP implementation = method_getImplementation(method);
                NSLog(@"---start invoke method-----");
                implementation();
                NSLog(@"---end invoke method-----");
            }
            for (int a = 0; a < argumentCount; a++) {
                NSLog(@"|----%d argument type: %s", a, method_copyArgumentType(method, a));
            }
        }
        free(methodList);
        // add a new method to class
        IMP addMethodImp = class_getMethodImplementation(objc_getClass("God"), @selector(speak));
        class_addMethod(personClass, @selector(speak), addMethodImp, "V@:");
        [person performSelector:@selector(speak)];
        NSLog(@"before replace method------");
        [person printInfo:@"person can print info"];
        IMP replaceMethodImp = class_getMethodImplementation(objc_getClass("God"), @selector(output));
        class_replaceMethod(personClass, @selector(printInfo:), replaceMethodImp, "V@:");
        NSLog(@"after replace method------");
        [person printInfo:@"person printinfo has been replaced!"];
        BOOL respond = class_respondsToSelector(personClass, @selector(printInfo:));
        // now Person cannot respond to output selector
        NSLog(@"person can respond output -> %d", respond);
        // class version
        class_setVersion(personClass, 1);
        int version = class_getVersion(personClass);
        NSLog(@"Person class version: %d", version);
        /*
        // Framework or Dynamic Libraries
        NSLog(@"===================Libraries=======================");
        unsigned int imageCount;
        const char **imageNames = objc_copyImageNames(&imageCount);
        for (unsigned int i = 0; i < imageCount; i++) {
            const char *imageName = imageNames[i];
            NSLog(@"%d image name: %s", (i + 1), imageName);
        }
        unsigned int classCount;
        const char **classNames = objc_copyClassNamesForImage("/System/Library/PrivateFrameworks/UIFoundation.framework/Versions/A/UIFoundation", &classCount);
        for (unsigned int i = 0; i < classCount; i++) {
            const char *classname = classNames[i];
            NSLog(@"%d class name: %s", (i + 1), classname);
        }
        
        NSLog(@"===================Classes=======================");
        unsigned int classout;
        Class *classList = objc_copyClassList(&classout);
        for (unsigned int i = 0; i < classout; i++) {
            Class class = classList[i];
            NSLog(@"%d class name: %s", (i + 1), class_getName(class));
        }*/
        NSLog(@"===================Protocol=======================");
        unsigned int protocolCount;
        Protocol *__unsafe_unretained *protocolList = class_copyProtocolList(personClass, &protocolCount);
        for (unsigned int i = 0; i < protocolCount; i++) {
            Protocol *protocol = protocolList[i];
            NSLog(@"%d protocol name: %s", (i + 1), protocol_getName(protocol));
            // method
            unsigned int requiredCount;
            struct objc_method_description *p_methodList = protocol_copyMethodDescriptionList(protocol, YES, YES, &requiredCount);
            for (unsigned int im = 0; im < requiredCount; im++) {
                struct objc_method_description m_description = p_methodList[im];
                NSLog(@"|--protocol: %s, method->name: %s, types: %s", protocol_getName(protocol), sel_getName(m_description.name), m_description.types);
            }
            free(p_methodList);
        }
        free(protocolList);

        NSLog(@"|===================Protocols=======================");
        unsigned int allProtocol;
        //Returns an array of all the protocols known to the runtime
        Protocol * __unsafe_unretained *allProtocols = objc_copyProtocolList(&allProtocol);
        for (unsigned int i = 0; i < allProtocol; i++) {
            Protocol *pro = allProtocols[i];
            NSLog(@"%d protocol name: %s", (i + 1), protocol_getName(pro));
        }
    }
    return 0;
}
