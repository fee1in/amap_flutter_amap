//
//  AMapPolygonController.m
//  amap_flutter_map
//
//  Created by lly on 2020/11/12.
//

#import "AMapPolygonController.h"
#import "AMapPolygon.h"
#import "AMapJsonUtils.h"
#import "MAPolygon+Flutter.h"
#import "MAPolygonRenderer+Flutter.h"
#import "FlutterMethodChannel+MethodCallDispatch.h"

@interface AMapPolygonController ()

@property (nonatomic,strong) NSMutableDictionary<NSString*,AMapPolygon*> *polygonDict;
@property (nonatomic,strong) FlutterMethodChannel *methodChannel;
@property (nonatomic,strong) NSObject<FlutterPluginRegistrar> *registrar;
@property (nonatomic,strong) MAMapView *mapView;

@end


@implementation AMapPolygonController

- (instancetype)init:(FlutterMethodChannel*)methodChannel
             mapView:(MAMapView*)mapView
           registrar:(NSObject<FlutterPluginRegistrar>*)registrar {
    self = [super init];
    if (self) {
        _methodChannel = methodChannel;
        _mapView = mapView;
        _polygonDict = [NSMutableDictionary dictionaryWithCapacity:1];
        _registrar = registrar;
        
        __weak typeof(self) weakSelf = self;
        [_methodChannel addMethodName:@"polygons#update" withHandler:^(FlutterMethodCall * _Nonnull call, FlutterResult  _Nonnull result) {
            id polygonsToAdd = call.arguments[@"polygonsToAdd"];
            if ([polygonsToAdd isKindOfClass:[NSArray class]]) {
                [weakSelf addPolygons:polygonsToAdd];
            }
            id polygonsToChange = call.arguments[@"polygonsToChange"];
            if ([polygonsToChange isKindOfClass:[NSArray class]]) {
                [weakSelf changePolygons:polygonsToChange];
            }
            id polygonIdsToRemove = call.arguments[@"polygonIdsToRemove"];
            if ([polygonIdsToRemove isKindOfClass:[NSArray class]]) {
                [weakSelf removePolygonIds:polygonIdsToRemove];
            }
            result(nil);
        }];
    }
    return self;
}

- (nullable AMapPolygon *)polygonForId:(NSString *)polygonId {
    return _polygonDict[polygonId];
}

- (void)addPolygons:(NSArray*)polygonsToAdd {
    for (NSDictionary* polygonDict in polygonsToAdd) {
        AMapPolygon *polygon = [AMapJsonUtils modelFromDict:polygonDict modelClass:[AMapPolygon class]];
        // ???????????????????????????????????????????????????????????????????????????overlay??????
        if (polygon.id_) {
            _polygonDict[polygon.id_] = polygon;
        }
        [self.mapView addOverlay:polygon.polygon];
    }
}

- (void)changePolygons:(NSArray*)polygonsToChange {
    for (NSDictionary* polygonDict in polygonsToChange) {
        AMapPolygon *polygon = [AMapJsonUtils modelFromDict:polygonDict modelClass:[AMapPolygon class]];
        AMapPolygon *currentPolygon = _polygonDict[polygon.id_];
        NSAssert(currentPolygon != nil, @"???????????????Polygon?????????");
        [currentPolygon updatePolygon:polygon];
        MAOverlayRenderer *render = [self.mapView rendererForOverlay:currentPolygon.polygon];
        if (render && [render isKindOfClass:[MAPolygonRenderer class]]) { // render?????????????????????????????????????????????????????????
            [(MAPolygonRenderer *)render updateRenderWithPolygon:currentPolygon];
        }
    }
}

- (void)removePolygonIds:(NSArray*)polygonIdsToRemove {
    for (NSString* polygonId in polygonIdsToRemove) {
        if (!polygonId) {
            continue;
        }
        AMapPolygon* polygon = _polygonDict[polygonId];
        if (!polygon) {
            continue;
        }
        [self.mapView removeOverlay:polygon.polygon];
        [_polygonDict removeObjectForKey:polygonId];
    }
}

@end
