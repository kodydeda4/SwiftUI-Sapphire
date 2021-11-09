//
//  UserData.swift
//  Sapphire
//
//  Created by Kody Deda on 12/24/20.
//

import SwiftUI
import Combine
import ComposableArchitecture
import DynamicColor
import CombineSchedulers

struct GridState: Equatable {
  var macOSApplications: [MacOSApplicationState] = .allCases
  var alert: AlertState<GridAction>?
  var inFlight = false
  var selectedColor = Color.white
}

enum GridAction: Equatable {
  
  // Root
  case onAppear
  case save
  case load
  
  // macOSApplication
  case macOSApplication(index: Int, action: MacOSApplicationAction)
  
  // Grid
  case selectAllButtonTapped
  case selectModifiedButtonTapped
  case selectAll
  case deselectAll
  case updateSelectedColor(Color)
  
  // Set Icons
  case setSystemApplications
  case setSystemApplicationsResult(Result<Bool, NSUserAppleScriptTaskError>)
  case cancelSetSystemApplications
  case createSetIconsAlert
  case dismissSetIconsAlert
  
  // Reset Icons
  case resetSystemApplications
  case resetSystemApplicationsResult(Result<Bool, NSUserAppleScriptTaskError>)
  case cancelResetSystemApplications
  case createResetIconsAlert
  case dismissResetIconsAlert
}

struct GridEnvironment {
  let stateURL: URL = URL.ApplicationSupport.appendingPathComponent("GridState.json")
  let client: AppIconCustomizerClient
//  let scheduler: AnySchedulerOf<DispatchQueue>
}


let gridReducer = Reducer<GridState, GridAction, GridEnvironment>.combine(
  macOSApplicationReducer.forEach(
    state: \.macOSApplications,
    action: /GridAction.macOSApplication(index:action:),
    environment: { _ in () }
  ),
  Reducer { state, action, environment in
    struct GridRequestId: Hashable {}
    
    
    switch action {
      
      // MARK:- root
      
    case .onAppear:
      return Effect(value: .load)
      
    case .save:
      let _ = JSONEncoder().writeState(state.macOSApplications, to: environment.stateURL)
      return .none
      
    case .load:
      switch JSONDecoder().decodeState(ofType: [MacOSApplicationState].self, from: environment.stateURL) {
      case let .success(decodedState):
        state.macOSApplications = decodedState
      case let .failure(error):
        print(error.localizedDescription)
      }
      return .none
      
      // MARK:- macOSApplication
      
    case let .macOSApplication(index, action):
      switch action {
        
      case .toggleSelected:
        state.macOSApplications[index].selected.toggle()
        return .none
        
      case .modifyIconButtonTapped:
        return Effect(value: .createSetIconsAlert)
        
      default:
        break
      }
      return Effect(value: .save)
      
      // MARK:- SetIcons
      
    case .setSystemApplications:
      state.inFlight = true
      return environment.client.setIcons(state.macOSApplications, state.selectedColor)
      
    case .setSystemApplicationsResult(.success):
      state.macOSApplications = state.macOSApplications
        .reduce(set: \.modified, to: true, where: \.selected)
        .reduce(set: \.colorHex, to: state.selectedColor.hex, where: \.selected)
      
      state.inFlight = false
      return Effect(value: .deselectAll)
      
    case let .setSystemApplicationsResult(.failure(error)):
      state.inFlight = false
      return Effect(value: .deselectAll)
      
    case .cancelSetSystemApplications:
      state.inFlight = false
      return .cancel(id: GridRequestId())
      
      // MARK:- SetIcons - alert
      
    case .createSetIconsAlert:
      state.alert = AlertState(
        title: "Password Required",
        message: "Requesting permission to modify system icons.",
        primaryButton: .destructive("Continue", send: .setSystemApplications),
        secondaryButton: .cancel()
      )
      return .none
      
    case .dismissSetIconsAlert:
      state.alert = nil
      return .none
      
      // MARK:- ResetIcons
    case .resetSystemApplications:
      state.inFlight = true
      return environment.client.resetIcons(state.macOSApplications)
      
    case .resetSystemApplicationsResult(.success):
      state.macOSApplications = state.macOSApplications.reduce(set: \.modified, to: false, where: \.selected)
      state.inFlight = false
      return Effect(value: .deselectAll)
      
    case let .resetSystemApplicationsResult(.failure(error)):
      state.inFlight = false
      return Effect(value: .deselectAll)
      
    case .cancelResetSystemApplications:
      state.inFlight = false
      return .cancel(id: GridRequestId())
      
      // MARK:- ResetIcons - alert
      
    case .createResetIconsAlert:
      state.alert = .init(
        title: "Password Required",
        message: "Requesting permission to modify system icons.",
        primaryButton: .destructive("Continue", send: .resetSystemApplications),
        secondaryButton: .cancel()
      )
      return .none
      
    case .dismissResetIconsAlert:
      state.alert = nil
      return .none
      
      // MARK:- select
      
    case .selectAllButtonTapped:
      state.macOSApplications =
      state.macOSApplications.reduce(set: \.selected, to: !state.macOSApplications.allSatisfy(\.selected))
      return .none
      
    case .selectAll:
      state.macOSApplications =
      state.macOSApplications.reduce(set: \.selected, to: true)
      return .none
      
    case .deselectAll:
      state.macOSApplications =
      state.macOSApplications.reduce(
        set: \.selected,
        to: false
      )
      return Effect(value: .save)
      
    case .selectModifiedButtonTapped:
      switch state.macOSApplications.filter(\.modified).allSatisfy(\.selected) && state.macOSApplications.filter(\.selected).allSatisfy(\.modified) {
        
      case true:
        return Effect(value: .deselectAll)
        
      case false:
        state.macOSApplications = state.macOSApplications.reduce(set: \.selected, to: \.modified)
      }
      return .none
      
      // MARK:- color
      
    case let .updateSelectedColor(color):
      state.selectedColor = color
      
      return .none
    }
  }
    .debug()
)

extension GridState {
  static let defaultStore = Store(
    initialState: .init(),
    reducer: gridReducer,
    environment: .init(
      client: .live//,
//      scheduler: .main
    )
  )
}


