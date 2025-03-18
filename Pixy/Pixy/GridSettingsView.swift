//
//  GridSettingsView.swift
//  Pixy
//
//  Created by Lorenzo Mazza on 15/03/25.
//

import SwiftUI

struct GridSettingsView: View {
    @Binding var rows: Int
    @Binding var columns: Int

    var body: some View {
        VStack {
            Text("Configura la Griglia")
            Stepper("Righe: \(rows)", value: $rows, in: 1...20)
            Stepper("Colonne: \(columns)", value: $columns, in: 1...20)
        }
    }
}
