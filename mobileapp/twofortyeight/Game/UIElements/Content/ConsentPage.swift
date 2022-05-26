//
//  ConsentPage.swift
//  twofortyeight
//
//  Created by LongHuy Nguyen on 4/3/22.
//  Copyright © 2022 Carlos Corrêa. All rights reserved.
//

import SwiftUI
import URLImage

struct ConsentPage: View {
	@Binding var showConsent:Bool
	@State private var agreed = false
	@State private var holdPhone = false
    
    let instructions: String
    let user_agreements: [String]
    let url: URL
	
	var body: some View {
		VStack() {
			HeaderBarTitle(title: "GAME AGREEMENT", size: 20)
			
			URLImage(url) { image in
				image
					.resizable()
					.aspectRatio(contentMode: .fit)
			}
            ConsentAgreement(showConsent: $showConsent, instructions: instructions, user_agreements:user_agreements)
				.padding([.leading], 4)
		}
	}
}

struct ConsentAgreement: View {
	@Environment(\.colorScheme) var colorScheme
	@Binding var showConsent:Bool
	@State private var agreed = false
	@State private var holdPhone = false
    @State private var marks:[Bool] //checkboxs state list, true==checked, false==unchecked  for user_agreements
    let instructions: String
    let user_agreements: [String]
    
    init(showConsent: Binding<Bool>, instructions: String, user_agreements:[String]){
        _showConsent=showConsent
        self.instructions=instructions
        self.user_agreements=user_agreements
        
        print(self.user_agreements);
        print(self.user_agreements.count);
        
        var temp:[Bool]=[]  //init the marks variable, which is a State variable, based on the length of user_agreements
        for _ in 0..<user_agreements.count{
            print("append")
            temp.append(false);
        }
        self._marks = State(initialValue: temp);
        print(self.marks)
        
    }
	var body: some View {
		VStack() {
            
            
			if colorScheme == .dark {
				CheckboxField(id: "agreed", label: "I agree that the survey data is being collected for research purposes and that I will hold the phone as described in the image above for the duration of the experiment.", isMarked: $agreed).colorInvert()
				CheckboxField(id: "holdPhone", label: instructions, isMarked: $holdPhone).colorInvert()
                List(user_agreements, id: \.self) {
                    user_agreement  in CheckboxField(id: "agreed", label: user_agreement, isMarked: $agreed).colorInvert()
                }
			} else {
				CheckboxField(id: "agreed", label: "I agree that the survey data is being collected for research purposes and that I will hold the phone as described in the image above for the duration of the experiment.", isMarked: $agreed)
				CheckboxField(id: "holdPhone", label: instructions, isMarked: $holdPhone)
                List{
                    ForEach(Array(user_agreements.enumerated()), id: \.offset) {
                    
                        index, user_agreement  in CheckboxField(id: "agreed", label: user_agreement, isMarked: $marks[index])
                    }
                }  // display the user_agreements
                
                //user_agreements.enumerated().map(CheckboxField(id: "agreed", label: $0.element, isMarked: $marks[$0.offset]))
			}
            
			Button(action: {
				self.showConsent = false
			}) {
				Text("OK")
			}
			.padding()
			.font(.system(size: 35, weight: .medium, design: .rounded))
            .disabled(marks.contains(false))  // check there is no false in marks list
		}
	}
}

struct CheckboxField: View {
	let id: String
	let label: String
	let size: CGFloat
	let color: Color
	let textSize: Int

	@Binding var isMarked: Bool
	
	init(
	id: String,
	label:String,
	size: CGFloat = 20,
	color: Color = Color.black.opacity(0.68),
	textSize: Int = 30,
	isMarked: Binding<Bool>
	) {
		self.id = id
		self.label = label
		self.size = size
		self.color = color
		self.textSize = textSize
		self._isMarked = isMarked
	}
	
	
	var body: some View {
		Button(action:{
			self.isMarked.toggle()
		}) {
			HStack(alignment: .center, spacing: 10) {
				Image(systemName: self.isMarked ? "checkmark.square" : "square")
				.renderingMode(.original)
				.resizable()
				.aspectRatio(contentMode: .fit)
				.frame(width: 20, height: 20)
				Text(label)
				.font(Font.system(size: size))
				.foregroundColor(Color.black.opacity(0.87))
				Spacer()
			}.foregroundColor(self.color)
		}
		.foregroundColor(Color.white)
	}
}
