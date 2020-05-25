/**
 * Copyright (c) 2014-present, Facebook, Inc. All rights reserved.
 *
 * You are hereby granted a non-exclusive, worldwide, royalty-free license to use,
 * copy, modify, and distribute this software in source code or binary form for use
 * in connection with the web services and APIs provided by Facebook.
 *
 * As with any software that integrates with the Facebook platform, your use of
 * this software is subject to the Facebook Developer Principles and Policies
 * [http://developers.facebook.com/policy/]. This copyright notice shall be
 * included in all copies or substantial portions of the software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
 * FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
 * COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
 * IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
 * CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

package com.facebook.unity;

import com.facebook.share.internal.ShareFeedContent;
import com.facebook.share.model.ShareLinkContent;
import com.facebook.share.model.SharePhoto;
import com.facebook.share.model.SharePhotoContent;
import com.facebook.share.model.ShareVideo;
import com.facebook.share.model.ShareVideoContent;
import com.facebook.share.widget.ShareDialog;

import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.net.Uri;
import android.os.Bundle;

class FBDialogUtils {
    public static ShareLinkContent.Builder createShareContentBuilder(Bundle params) {
        ShareLinkContent.Builder  builder = new ShareLinkContent.Builder();

        if (params.containsKey("content_title")) {
            builder.setContentTitle(params.getString("content_title"));
        }

        if (params.containsKey("content_description")) {
            builder.setContentDescription(params.getString("content_description"));
        }

        if (params.containsKey("content_url")) {
            builder.setContentUrl(Uri.parse(params.getString("content_url")));
        }

        if (params.containsKey("photo_url")) {
            builder.setImageUrl(Uri.parse(params.getString("photo_url")));
        }

        return builder;
    }

    public static SharePhotoContent.Builder createPhotoContentBuilder(Bundle params) {
        SharePhoto.Builder photoBuilder = new SharePhoto.Builder();

        if (params.containsKey("bitmap_path")) {
            Bitmap bitmap = BitmapFactory.decodeFile(params.getString("bitmap_path"));
            photoBuilder.setBitmap(bitmap);
        }

        if (params.containsKey("photo_url")) {
            photoBuilder.setImageUrl(Uri.parse(params.getString("photo_url")));
        }

        if (params.containsKey("user_generated")) {
            photoBuilder.setUserGenerated(Boolean.parseBoolean(params.getString("user_generated")));
        }

        if (params.containsKey("caption")) {
            photoBuilder.setCaption(params.getString("caption"));
        }

        SharePhotoContent.Builder contentBuilder = new SharePhotoContent.Builder();
        contentBuilder.addPhoto(photoBuilder.build());

        return contentBuilder;
    }

    public static ShareVideoContent.Builder createVideoContentBuilder(Bundle params) {
        ShareVideoContent.Builder videoContentBuilder = new ShareVideoContent.Builder();

        if (params.containsKey("content_title")) {
            videoContentBuilder.setContentTitle(params.getString("content_title"));
        }

        if (params.containsKey("content_description")) {
            videoContentBuilder.setContentDescription(params.getString("content_description"));
        }

        if (params.containsKey("preview_photo_url")) {
            SharePhoto.Builder previewPhotoBuilder = new SharePhoto.Builder();
            previewPhotoBuilder.setImageUrl(Uri.parse(params.getString("preview_photo_url")));
            videoContentBuilder.setPreviewPhoto(previewPhotoBuilder.build());
        }

        if (params.containsKey("video_url")) {
            ShareVideo.Builder videoBuilder = new ShareVideo.Builder();
            videoBuilder.setLocalUrl(Uri.parse(params.getString("video_url")));
            videoContentBuilder.setVideo(videoBuilder.build());
        }

        return videoContentBuilder;
    }

    public static ShareFeedContent.Builder createFeedContentBuilder(Bundle params) {
        ShareFeedContent.Builder builder = new ShareFeedContent.Builder();

        if (params.containsKey("toId")) {
            builder.setToId(params.getString("toId"));
        }

        if (params.containsKey("link")) {
            builder.setLink(params.getString("link"));
        }

        if (params.containsKey("linkName")) {
            builder.setLinkName(params.getString("linkName"));
        }

        if (params.containsKey("linkCaption")) {
            builder.setLinkCaption(params.getString("linkCaption"));
        }

        if (params.containsKey("linkDescription")) {
            builder.setLinkDescription(params.getString("linkDescription"));
        }

        if (params.containsKey("picture")) {
            builder.setPicture(params.getString("picture"));
        }

        if (params.containsKey("mediaSource")) {
            builder.setMediaSource(params.getString("mediaSource"));
        }

        return builder;
    }

    public static ShareDialog.Mode intToMode(int mode) {
        switch (mode) {
            case 0:
                return ShareDialog.Mode.AUTOMATIC;
            case 1:
                return ShareDialog.Mode.NATIVE;
            case 2:
                return ShareDialog.Mode.WEB;
            case 3:
                return ShareDialog.Mode.FEED;
            default:
                return null;
        }
    }
}
