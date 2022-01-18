//
//  String+Extensions.swift
//  spectrum_tracker
//
//  Created by Alex Chang on 2020/9/29.
//  Copyright © 2020 JO. All rights reserved.
//

import Foundation

extension String {
    func localized() -> String {
        return NSLocalizedString(self, comment: "")
    }
    
    func htmlAttributedString(color: UIColor, font: UIFont = UIFont.systemFont(ofSize: 15)) -> NSAttributedString? {
        let htmlTemplate = """
        <!doctype html>
        <html>
          <head>
            <style>
              body {
                color: \(color.hexString!);
                font-family: '\(font.fontName)', '-apple-system';
                font-size: \(font.pointSize)px;
              }
              h5 {
                color: \(color.hexString!);
                font-family: '\(font.fontName)', '-apple-system';
                font-size: \(font.pointSize + 1)px;
              }
              p {
                margin: 4px;
              }
            </style>
          </head>
          <body>
            \(self)
          </body>
        </html>
        """

        guard let data = htmlTemplate.data(using: .utf8) else {
            return nil
        }

        guard let attributedString = try? NSAttributedString(
            data: data,
            options: [.documentType: NSAttributedString.DocumentType.html,
                      .characterEncoding: String.Encoding.utf8.rawValue],
            documentAttributes: nil
            ) else {
            return nil
        }

        return attributedString
    }
}
