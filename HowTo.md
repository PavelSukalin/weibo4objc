#weibo4objc的使用说明

# 说明 #

本文主要是对使用weibo4objc的具体说明.

# 细节 #

Weibo对象是对外提供服务的接口,所有的数据类型都封装在adt目录下,使用者可以仅仅关注这部分内容.
首先需要import Weibo.h,初始化weibo对象,并设置用户名密码和appkey,如下:
```
	Weibo * weibo = [[[Weibo alloc]init] autorelease];
	[weibo set_username:@"loopb@sina.cn"];
	[weibo set_password:@"111111"];
	[weibo set_consumerKey:@"111111"];
```

注意:V1版本先不支持oauth方式认证.

对微博进行操作只需要调用线上接口对应的方法,如:
```
       @try{
	Status * statusme = [weibo statusUpdate:@"地是吧1123345" inReplyToStatusId:4520497159 latitude:1 longitude:1];
	NSLog([statusme description]);	
	}
	@catch (id ex) {
		printf("aaa");
		NSLog(@"%@",ex);
	}

	NSArray * statuses = [weibo getPublicTimeline:5];

	for(Status * status in statuses){
		NSLog([status description]);
	}
	[pool release];
```

需要注意的是,通过别的方法返回的对象已经被设置为autorelease,用户不需要进行其他操作.