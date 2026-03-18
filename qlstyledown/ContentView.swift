//
//  ContentView.swift
//  qlstyledown
//
//  Created by SeminOH on 3/18/26.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.richtext")
                .imageScale(.large)
                .font(.system(size: 48))
                .foregroundStyle(.tint)

            Text("qlstyledown")
                .font(.title)
                .fontWeight(.bold)

            Text("Quick Look Extension이 등록되었습니다.")
                .foregroundStyle(.secondary)

            Text("Finder에서 .md 파일을 선택하고 Space를 눌러 미리보기하세요.")
                .foregroundStyle(.secondary)
                .font(.callout)
        }
        .padding(40)
        .frame(minWidth: 400, minHeight: 250)
    }
}

#Preview {
    ContentView()
}
