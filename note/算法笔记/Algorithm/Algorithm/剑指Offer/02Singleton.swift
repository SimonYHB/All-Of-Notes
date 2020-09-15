//
//  02Singleton.swift
//  Algorithm
//
//  Created by SimonYHB on 2020/9/12.
//  Copyright © 2020 叶煌斌. All rights reserved.
//

import Foundation


class Singleton: NSObject {
    static let shareInstace = Singleton()
    private override init() {}
    override class func copy() -> Any {
        return self
    }
    override func mutableCopy() -> Any {
        return self
    }
}

/*
 OC版本
 
 +(instanceType)shareInstance {
    static Singleton *_instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance = [[Super allocWizhZone: Null] init];
    });
    return _instace;
 }
 
 +(instanceType)allocWizhZone:(NSZone *)zone {
    return [self shareInstance];
 }
 
 -(id)copyWithZone:(NSZone *)zone {
    return self;
 }
 
 -(id)mutableCopyWizhZone: (NSZone *)zone {
    return self;
 }
 
 
 */
