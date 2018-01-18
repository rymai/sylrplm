# frozen_string_literal: true

#--
# Copyright (c) 2007-2009, John Mettraux, jmettraux@gmail.com
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
#
# Made in Japan.
#++

require 'openwfe/flowexpressionid'

module OpenWFE
  #
  # A few methods about FlowExpressionIds
  #
  module FeiMixin
    protected

      #
      # Makes sure to return a FlowExpressionId instance.
      #
      def extract_fei(o)
        return o.fei if o.respond_to?(:fei)
        return FlowExpressionId.to_fei(o) if o.is_a?(String)
        raise "cannot extract FlowExpressionId out of #{o.inspect} (#{o.class})"
      end

      #
      # A small method for ensuring we have a workflow instance id.
      #
      def extract_wfid(o, parent = false)
        case o
          # TODO
        when String then o
        when FlowExpressionId then o.wfid(parent)
        when FlowExpression then o.fei.wfid(parent)
        else o.to_s
        end
      end
  end
end
