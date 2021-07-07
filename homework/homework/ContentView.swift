//
//  ContentView.swift
//  homework
//
//  Created by 정지인님/Comm Media Cell on 2021/07/06.
//

import SwiftUI

struct ContentView: View {
    @State
    private var isActivated:Bool=false
    
    @State
    private var showDetails:Bool=false
    
    var body: some View {
        NavigationView{
        VStack{
            MyHstackView()
            MyHstackView()
            MyHstackView()
            
            NavigationLink(destination: MyTextView()) { (/*@START_MENU_TOKEN@*/Text("Navigate")/*@END_MENU_TOKEN@*/ )}
            Button(action: {self.showDetails.toggle()})
            {
                /*@START_MENU_TOKEN@*/Text("Button")/*@END_MENU_TOKEN@*/
            }
            if showDetails{
                Text("you should see me in a crown")
                    .font(.largeTitle)
                
            }
        }
        }
    }
}
    
struct MyHstackView:View{
    var body: some View{
        HStack{
            Text("1!")
                .padding()
            Text("2!")
                .padding()
            Text("3!")
                .padding()
            
        
        }.background(Color.pink)
    }
}
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
} //이걸 통해 오른쪽 화면을 볼 수 있다.
