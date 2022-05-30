//
//  InstructionPage.swift
//  twofortyeight
//
//  Created by Sandeep Kollannur on 5/30/22.
//  Copyright © 2022 Carlos Corrêa. All rights reserved.
//

import SwiftUI
import URLImage
struct InstructionPage: View {
    @Binding var showInstruction:Bool
    let user_instructions: String
    
    var body: some View {
        VStack(spacing: 0) {
            HeaderBarTitle(title: "GAME INSTRUCTION", size: 20)
        
            URLImage(URL(string: "https://images.pexels.com/photos/36445/rose-close-up-pink-flower.jpg")!) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            }
            Text(user_instructions).font(.system(size: 25)).bold()
            
            Button(action: {
                self.showInstruction = false
            }) {
                Text("OK")
            }
            .padding()
            .font(.system(size: 35, weight: .medium, design: .rounded))
    
        }
    }
}
