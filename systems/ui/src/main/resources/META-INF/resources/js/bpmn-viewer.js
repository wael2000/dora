var diagramUrl = 'bpmn/requests.bpmn2';
var currentTask;
// viewer instance
var bpmnViewer = new BpmnJS({
    container: '#canvas',
    overlays: {
        defaults: {
          show: { minZoom: 1 },
          scale: true
        }
      }
});


function processState(state){
    var overlays = bpmnViewer.get('overlays');
    
    var overlayHtml = $('<div>Mixed up the labels?</div>');

    overlayHtml.click(function(e) {
        alert('someone clicked me');
    });

    // attach the overlayHtml to a node
    overlays.add('SCAN_OK', {
    position: {
        bottom: 0,
        right: 0
    },
    html: overlayHtml
    });
}
/**
 * Open diagram in our viewer instance.
 *
 * @param {String} bpmnXML diagram to display
 */
async function openDiagram(bpmnXML) {
    // import diagram
    try {
        await bpmnViewer.importXML(bpmnXML);
        // access viewer components
        var canvas = bpmnViewer.get('canvas');
        // zoom to fit full viewport
        canvas.zoom('fit-viewport');
        if(currentTask == "AssignPhysician")
            currentTask = "UserTask_1";
        else if(currentTask == "CaseAssessment")
            currentTask = "_A1D986A5-B892-4AC7-915F-6F6E16ADD7EE";
        else 
            currentTask = "";
        // UserTask_1 : assign physician
        // _A1D986A5-B892-4AC7-915F-6F6E16ADD7EE : case assessment
        canvas.addMarker(currentTask, 'highlight');        
        // add marker
        // canvas.addMarker('SCAN_OK', 'needs-discussion');
    } catch (err) {
        console.error('could not import BPMN 2.0 diagram', err);
    }
}