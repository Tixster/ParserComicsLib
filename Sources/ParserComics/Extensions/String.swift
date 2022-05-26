//
//  File.swift
//  
//
//  Created by Кирилл Тила on 26.05.2022.
//

import Foundation

public extension String {

    /**
     Получение числа с помощью регулярного вырадения
     
     - parameter pattern: Ваше регулярное выражение.
     - returns: Вернёт 0, если регулярное выражение невалидное
     */
    func getNumbers(pattern: String) -> Int {
        let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive)
        guard let match = regex?.firstMatch(in:  self, options: [],
                                            range: NSRange(location: 0, length: self.count))
        else { return 0 }
        guard let rangeText = Range(match.range, in: self) else { return 0 }
        let stringNumber = String(self[rangeText])
        let intNumber = Int(stringNumber)
        return intNumber ?? 0
    }

}
