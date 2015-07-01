import 'package:polymer/polymer.dart';

@CustomTag('checkbox-group')
class CheckboxGroup extends PolymerElement {
  
  @observable List<CheckboxElement> checkboxes = [new CheckboxElement("test", true), new CheckboxElement("test 2", true)];
  var count = 0;

  CheckboxGroup.created() : super.created();
  
//  @override
//  ready() {
//    super.ready();
//    checkboxes.clear();
//    addCheckBox("test", false);
//    addCheckBox("another", true);
//    addCheckBox("three", false);
//  }
  
  addCheckBox(String label, bool checked) {
    checkboxes.insert(count++, new CheckboxElement(label, checked));
    
  }

}

class CheckboxElement extends Observable {
  @observable String label;
  @observable bool checked;
  
  CheckboxElement(this.label, this.checked);
  
}
