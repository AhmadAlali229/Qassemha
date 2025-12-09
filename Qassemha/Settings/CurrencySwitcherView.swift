//
//  CurrencySwitcherView.swift
//  Qassemha
//
//  Created on 2025-11-10.
//

import SwiftUI

struct CurrencySwitcherView: View {
    @ObservedObject var currencyManager = CurrencyManager.shared
    @State private var showCurrencyPicker = false

    var body: some View {
        Button(action: {
            showCurrencyPicker = true
        }) {
            HStack(spacing: 4) {
                Text(currencyManager.currencySymbol)
                    .font(.system(size: 16, weight: .semibold))
                Text(currencyManager.currencyCode)
                    .font(.system(size: 12, weight: .medium))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.blue.opacity(0.8))
            .cornerRadius(8)
        }
        .sheet(isPresented: $showCurrencyPicker) {
            CurrencyPickerSheet(currencyManager: currencyManager, isPresented: $showCurrencyPicker)
        }
    }
}

struct CurrencyPickerSheet: View {
    @ObservedObject var currencyManager: CurrencyManager
    @Binding var isPresented: Bool

    var body: some View {
        NavigationView {
            List {
                ForEach(Currency.allCases, id: \.self) { currency in
                    Button(action: {
                        currencyManager.setCurrency(currency)
                        isPresented = false
                    }) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(currency.name)
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                Text("\(currency.symbol) \(currency.code)")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            if currencyManager.selectedCurrency == currency {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.blue)
                            }
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .navigationTitle("Select Currency")
            .navigationBarItems(trailing: Button("Done") {
                isPresented = false
            })
        }
    }
}
