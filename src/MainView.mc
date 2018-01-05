using Toybox.System;
using Toybox.WatchUi;

using TextInput;

class MainView extends WatchUi.View {
  var timer;

  function initialize() {
    View.initialize();
    timer = new Timer.Timer();
  }

  function onShow() {
    timer.start(method(:update), 100, true);
  }

  function onHide() {
    timer.stop();
  }

  function update() {
    var provider = currentProvider();
    switch (provider) {
    case instanceof TimeBasedProvider:
      provider.update();
      break;
    }
    WatchUi.requestUpdate();
  }

  function onUpdate(dc) {
    dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
    dc.clear();
    var provider = currentProvider();
    var font = Graphics.FONT_MEDIUM;
    var fh = dc.getFontHeight(font);
    dc.drawText(dc.getWidth()/2, dc.getHeight()/2 - 2*fh, font,
                provider ? provider.name_ : "Tap to start", Graphics.TEXT_JUSTIFY_CENTER);
    switch (provider) {
    case instanceof TimeBasedProvider:
      var delta = provider.next_ - Time.now().value();
      dc.drawText(dc.getWidth()/2, dc.getHeight()/2 + fh, font,
                  delta, Graphics.TEXT_JUSTIFY_CENTER);
    case instanceof CounterBasedProvider:
      dc.drawText(dc.getWidth()/2, dc.getHeight()/2, font,
                  provider.code_, Graphics.TEXT_JUSTIFY_CENTER);
    }
  }
}

class MainViewDelegate extends WatchUi.BehaviorDelegate {
  function initialize() {
    BehaviorDelegate.initialize();
  }

  function onKey(event) {
    var key = event.getKey();
    if (key == KEY_ENTER) {
      var provider = currentProvider();
      switch (provider) {
      case instanceof CounterBasedProvider:
        provider.update();
        WatchUi.requestUpdate();
        return;
      }
    }
    BehaviorDelegate.onKey(event);
  }

  function onSelect() {
    if (_providers.size() == 0) {
      var view = new TextInput.TextInputView("Enter name", TextInput.ALPHANUM);
      WatchUi.pushView(view, new NameInputDelegate(view), WatchUi.SLIDE_RIGHT);
    } else {
      var menu = new WatchUi.Menu();
      menu.setTitle("OTP Providers");
      for (var i = 0; i < _providers.size(); i++) {
        menu.addItem(_providers[i].name_, i);
      }
      menu.addItem("New entry", :new_entry);
      menu.addItem("Delete entry", :delete_entry);
      WatchUi.pushView(menu, new ProvidersMenuDelegate(), WatchUi.SLIDE_LEFT);
    }
  }
}

class ProvidersMenuDelegate extends WatchUi.MenuInputDelegate {
  function initialize() {
    MenuInputDelegate.initialize();
  }
  function onMenuItem(item) {
    switch(item) {
    case :new_entry:
      var view = new TextInput.TextInputView("Enter name", TextInput.ALPHANUM);
      WatchUi.pushView(view, new NameInputDelegate(view), WatchUi.SLIDE_LEFT);
      return;
    case :delete_entry:
      var menu = new WatchUi.Menu();
      menu.setTitle("Delete provider");
      for (var i = 0; i < _providers.size(); i++) {
        menu.addItem(_providers[i].name_, _providers[i]);
      }
      WatchUi.pushView(menu, new DeleteMenuDelegate(), WatchUi.SLIDE_LEFT);
      return;
    default:
      _currentIndex = item;
      WatchUi.requestUpdate();
    }
  }
}

class DeleteMenuDelegate extends WatchUi.MenuInputDelegate {
  function initialize() {
    MenuInputDelegate.initialize();
  }
  function onMenuItem(item) {
    _providers.remove(item);
  }
}

var _enteredName = "";

class NameInputDelegate extends TextInput.TextInputDelegate {
  function initialize(view) {
    TextInputDelegate.initialize(view);
  }
  function onTextEntered(text) {
    _enteredName = text;
    var view = new TextInput.TextInputView("Enter key (Base32)", TextInput.BASE32);
    WatchUi.pushView(view, new KeyInputDelegate(view), WatchUi.SLIDE_LEFT);
  }
}

class KeyInputDelegate extends TextInput.TextInputDelegate {
  function initialize(view) {
    TextInputDelegate.initialize(view);
  }
  function onTextEntered(text) {
    _providers.add(new TimeBasedProvider(_enteredName, text, 30));
    _currentIndex = _providers.size() - 1;
    WatchUi.popView(WatchUi.SLIDE_RIGHT);
    WatchUi.popView(WatchUi.SLIDE_RIGHT);
  }
}
