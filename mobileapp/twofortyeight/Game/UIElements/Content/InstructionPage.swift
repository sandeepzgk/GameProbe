//
//  InstructionPage.swift
//  twofortyeight
//
//  Created by Sandeep Kollannur on 5/30/22.
//  Copyright © 2022 Carlos Corrêa. All rights reserved.
//

import SwiftUI
import URLImage
import LofeltHaptics
struct InstructionPage: View {
    @Binding var showInstruction:Bool
    var viewModel:GameViewModel
    let user_instructions: String
    @State private var buttonDisabled = true
    var body: some View {
        VStack(spacing: 0) {
            HeaderBarTitle(title: "GAME INSTRUCTION", size: 20)
        
//            URLImage(url) { image in
//                image
//                    .resizable()
//                    .aspectRatio(contentMode: .fit)
//            }
            
            
            Image(uiImage: UIImage(named: "instruction_image_720")!).resizable().aspectRatio(contentMode: .fit)
            
            Text(user_instructions).font(.system(size: 25)).bold()
            
            Button(action: {
                self.showInstruction = false
                self.viewModel.GameStart = true
            }) {
                Text("OK")
            }
            .padding()
            .font(.system(size: 35, weight: .medium, design: .rounded))
            .disabled(self.buttonDisabled == true)
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    self.buttonDisabled = false
                    print("time out ok")
                }
            }
        }
    }
}
