//
//  FourCharCode+StringLiteralConvertible.swift
//  OOPUtils
//
//  Created by OOPer in cooperation with shlab.jp, on 2014/12/14.
//  Last update on 2017/07/18.
//
//
/*
 Copyright (c) 2015-2017, OOPer(NAGATA, Atsuyuki)
 All rights reserved.
 
 Use of any parts(functions, classes or any other program language components)
 of this file is permitted with no restrictions, unless you
 redistribute or use this file in its entirety without modification.
 In this case, providing any sort of warranties or not is the user's responsibility.
 
 Redistribution and use in source and/or binary forms, without
 modification, are permitted provided that the following conditions are met:
 
 1. Redistributions of source code must retain the above copyright notice,
 this list of conditions and the following disclaimer.
 2. Redistributions in binary form must reproduce the above copyright notice,
 this list of conditions and the following disclaimer in the documentation
 and/or other materials provided with the distribution.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
 ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

import Foundation
///FourCharCode is a typealias of UInt32 (OSStatus)
extension FourCharCode {
    
    public init(from4char string: String) {
        guard string.utf16.count == 4 else {
            fatalError("FourCharCode length must be 4!")
        }
        var code: FourCharCode = 0
        for char in string.utf16 {
            if char > 0xFF {
                fatalError("FourCharCode must contain only ASCII characters!")
            }
            code = (code << 8) + FourCharCode(char)
        }
        self = code
    }
    
    public init(networkOrder value: UInt32) {
        self.init(bigEndian: value)
    }
    
    public var fourCharString: String {
        let bytes: [UInt8] = [
            UInt8(extendingOrTruncating: (self >> 24)),
            UInt8(extendingOrTruncating: (self >> 16)),
            UInt8(extendingOrTruncating: (self >> 8)),
            UInt8(extendingOrTruncating: self),
            ]
        return String(bytes: bytes, encoding: .isoLatin1)!
    }
    
    public var possibleFourCharString: String {
        var bytes: [UInt8] = [
            UInt8(extendingOrTruncating: (self >> 24)),
            UInt8(extendingOrTruncating: (self >> 16)),
            UInt8(extendingOrTruncating: (self >> 8)),
            UInt8(extendingOrTruncating: self),
            ]
        for i in 0..<4 {
            if bytes[i] < 0x20 || bytes[i] > 0x7E {
                bytes[i] = UInt8(("?" as UnicodeScalar).value)
            }
        }
        return String(bytes: bytes, encoding: .isoLatin1)!
    }
}

