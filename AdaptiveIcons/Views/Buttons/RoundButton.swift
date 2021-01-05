//
//  RoundButton.swift
//  AdaptiveIcons
//
//  Created by Kody Deda on 12/31/20.
//

import SwiftUI
import ComposableArchitecture

struct RoundButton: View {
    let store: Store<SelectedIconState, SelectedIconAction>
    var color: Color
    var action: () -> Void
    
    var body: some View {
        WithViewStore(store) { viewStore in
            Button(action: action) {
                ZStack {
                    Circle()
                        .foregroundColor(color)
                        .frame(width: 15, height: 15)
                    Circle()
                        .frame(width: 6, height: 6)
                        .foregroundColor(
                            Color.white.opacity(
                                viewStore.selectedBackgroundColor == color
                                    ? 1
                                    : 0
                            ))
                        .shadow(
                            color: Color.black.opacity(0.6),
                            radius: 2
                        )
                }
            }
        }
        .buttonStyle(BorderlessButtonStyle())
    }
}

struct RoundButton_Previews: PreviewProvider {
    static var previews: some View {
        HStack {
            ForEach([Color.blue, .purple, .pink, .red, .orange, .yellow, .green, .gray, .black, .white], id: \.self) { color in
                RoundButton(
                    store: SelectedIconState.defaultStore,
                    color: color,
                    action: {}
                )
            }
        }
        .padding()
    }
}
