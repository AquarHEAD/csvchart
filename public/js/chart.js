function app(frame_data, gt_data, rt_data) {
  line_option = {show: true, lineWidth: 0.8};

  dataset = {
    "frame": {data: frame_data, label: "Frame (ms)", lines: line_option},
    "gt": {data: gt_data, label: "GT (ms)", lines: line_option},
    "rt": {data: rt_data, label: "RT (ms)", lines: line_option}
  }

  options = {
    legend: {
      position: "ne",
      backgroundColor: "#EAE8FF"
    },
    colors: ["#FE7F2D", "#51A8DD", "#439775"],
    xaxis: {
      show: false
    },
    yaxis: {
      min: 0,
      max: 45,
    },
    crosshair: {
      mode: "x",
      color: "#EAE8FF",
    },
    grid: {
      backgroundColor: "#222",
      aboveData: false,
      markings: [
        {
          yaxis: {from: 1000/60, to: 1000/60},
          lineWidth: 1,
          color: "#0F0"
        },
        {
          yaxis: {from: 1000/30, to:1000/30},
          lineWidth: 1,
          color: "#FF0"
        }
      ]
    }
  };

  function draw_chart() {
    var data = [];
    $("#choices").find("input:checked").each(function () {
      key = $(this).attr("name");
      if (key && dataset[key]) {
        data.push(dataset[key]);
      }
    });
    $(function(){
      chart = $("#chart");
      plot = $.plot($("#chart"), data, options);

      pos60 = plot.pointOffset({ x: 0.5, y: 1000/60});
      chart.append('<div style="position:absolute;left:' + (pos60.left + 4) + 'px;top:' + (pos60.top-15) + 'px;color:#0F0;font-size:smaller">60 FPS</div>');

      pos30 = plot.pointOffset({ x: 0.5, y: 1000/30});
      chart.append('<div style="position:absolute;left:' + (pos30.left + 4) + 'px;top:' + (pos30.top-15) + 'px;color:#FF0;font-size:smaller">30 FPS</div>');
    });
  }

  $("#replot").click(draw_chart);
  draw_chart();
}
