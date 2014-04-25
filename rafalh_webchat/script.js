var last_msg = -1;

function js_updateChat()
{
	getChatMessages(last_msg.toString(),
		function(msgs)
		{
			var table = document.getElementById("msgs");
			var c = msgs ? msgs.length : 0;
			
			for(var i = 0; i < c; ++i)
			{
				var id = msgs[i][2].toString();
				if(id > last_msg)
				{
					last_msg = id;
					
					var row = document.createElement("tr");
					
					var buf = msgs[i][1].toString().htmlEntities();
					buf = buf.replace(/(#[0-9abcdef]{6})/gi, "</span><span style=\"color:$1\">");
					
					var cell = document.createElement("td");
					cell.className = "chattime";
					cell.innerHTML = "[" + msgs[i][0].toString() + "]";
					row.appendChild(cell);
					
					var cell2 = document.createElement("td");
					cell2.innerHTML = "<span class=\"chatmsg\">" + buf + "</span>";
					cell2.className = "chatmsg";
					row.appendChild(cell2);
					
					table.appendChild(row);
				}
			}
			
			while(table.children.length > 20)
				table.removeChild(table.firstChild);
		}
	);
}

function js_updateChatTimer()
{
	js_updateChat();
	setTimeout("js_updateChatTimer()", 500);
}

String.prototype.htmlEntities = function()
{
	return this.replace(/</g,'&lt;').replace(/>/g,'&gt;');
};

function js_sendChatMsg()
{
	var nick = document.getElementById("nick");
	var msg = document.getElementById("msg");
		
	if(nick.value == "Nick" || nick.value == "")
	{
		alert("Type a nick!");
		return 0;
	}
		
	if(msg.value == "Message" || msg.value == "")
	{
		alert("Type your message to send!");
		return 0;
	}
	
	sendChatMsg("", nick.value, msg.value, function(r) { });
	msg.value = '';
}

function js_nickB()
{
	var nick = document.getElementById( 'nick');
	if(nick.value=='') 
		nick.value='Nick';
}

function js_nickF()
{
	var nick = document.getElementById( 'nick'); 
	if(nick.value=='Nick')
		nick.value='';
}

function js_msgB()
{
	var msg = document.getElementById( 'msg');	
	if(msg.value == '') 
		msg.value = 'Message';
}

function js_msgF()
{
	var msg = document.getElementById( 'msg');
	if(msg.value == 'Message')
		msg.value = '';
}
