## vscode设置成中文

vscode默认的语言是英文，对于英文不好的小伙伴可能不太友好。简单几步教大家如何将vscode设置成中文。

1. 按快捷键“Ctrl+Shift+P”。
2. 在“vscode”顶部会出现一个搜索框。
3. 输入“configure language”，然后回车。
4. “vscode”里面就会打开一个语言配置文件。
5. 将“en-us”修改成“zh-cn”。
6. 按“Ctrl+S”保存设置。
7. 关闭“vscode”，再次打开就可以看到中文界面了。

## VScode用户设置

1. 打开设置

文件--首选项--设置，打开用户设置。VScode支持选择配置，也支持编辑setting.json文件修改默认配置。个人更倾向于编写json的方式进行配置，下面会附上我个人的配置代码

这里解析几个常用配置项：

（1）editor.fontsize用来设置字体大小，可以设置editor.fontsize : 14;

（2）files.autoSave这个属性是表示文件是否进行自动保存，推荐设置为onFocusChange——文件焦点变化时自动保存。

（3）editor.tabCompletion用来在出现推荐值时，按下Tab键是否自动填入最佳推荐值，推荐设置为on;

（4）editor.codeActionsOnSave中的source.organizeImports属性，这个属性能够在保存时，自动调整 import 语句相关顺序，能够让你的 import 语句按照字母顺序进行排列，推荐设置为true,即"editor.codeActionsOnSave": { "source.organizeImports": true }；

（5）editor.lineNumbers设置代码行号,即editor.lineNumbers ：true；

我的个人配置，供参考：

```json
{
  "files.associations": {
  "*.vue": "vue",
  "*.wpy": "vue",
  "*.wxml": "html",
  "*.wxss": "css"
  },
  "terminal.integrated.shell.windows": "C:\\Windows\\System32\\cmd.exe",
  "git.enableSmartCommit": true,
  "git.autofetch": true,
  "emmet.triggerExpansionOnTab": true,
  "emmet.showAbbreviationSuggestions": true,
  "emmet.showExpandedAbbreviation": "always",
  "emmet.includeLanguages": {
  "vue-html": "html",
  "vue": "html",
  "wpy": "html"
  },
  //主题颜色 
  //"workbench.colorTheme": "Monokai",
  "git.confirmSync": false,
  "explorer.confirmDelete": false,
  "editor.fontSize": 14,
  "window.zoomLevel": 1,
  "editor.wordWrap": "on",
  "editor.detectIndentation": false,
  // 重新设定tabsize
  "editor.tabSize": 2,
  //失去焦点后自动保存
  "files.autoSave": "onFocusChange",
  // #值设置为true时，每次保存的时候自动格式化；
  "editor.formatOnSave": false,
   //每120行就显示一条线
  "editor.rulers": [
  ],
  // 在使用搜索功能时，将这些文件夹/文件排除在外
  "search.exclude": {
      "**/node_modules": true,
      "**/bower_components": true,
      "**/target": true,
      "**/logs": true,
  }, 
  // 这些文件将不会显示在工作空间中
  "files.exclude": {
      "**/.git": true,
      "**/.svn": true,
      "**/.hg": true,
      "**/CVS": true,
      "**/.DS_Store": true,
      "**/*.js": {
          "when": "$(basename).ts" //ts编译后生成的js文件将不会显示在工作空中
      },
      "**/node_modules": true
  }, 
  // #让vue中的js按"prettier"格式进行格式化
  "vetur.format.defaultFormatter.html": "js-beautify-html",
  "vetur.format.defaultFormatter.js": "prettier",
  "vetur.format.defaultFormatterOptions": {
      "js-beautify-html": {
          // #vue组件中html代码格式化样式
          "wrap_attributes": "force-aligned", //也可以设置为“auto”，效果会不一样
          "wrap_line_length": 200,
          "end_with_newline": false,
          "semi": false,
          "singleQuote": true
      },
      "prettier": {
          "semi": false,
          "singleQuote": true
      }
  }
}
```

**最近经常有人微信问我，这个配置代码写在哪里？**

新版的vscode设置默认为UI的设置，而非之前的json设置。如果你想复制我上面这段代码进行配置，可以进行下面的修改

文件>首选项>设置 > 搜索workbench.settings.editor，选中json即可改成json设置；

**禁用自动更新**

文件 > 首选项 > 设置（macOS：代码 > 首选项 > 设置，搜索update mode并将设置更改为none。


**必备插件**

**1、View In Browser**

### 2、vscode-icons

改变编辑器里面的文件图标

### 3、Bracket Pair Colorizer

给嵌套的各种括号加上不同的颜色。

### 4、Auto Rename Tag

### 5、Path Intellisense

### 6、Markdown Preview

实时预览 markdown。

### 7、stylelint

CSS / SCSS / Less 语法检查

### 8、Import Cost

### 9、Prettier

比Beautify更好用的代码格式化插件

### 10、GitLens
